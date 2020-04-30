#!/usr/bin/env python

import glob
import re
import shutil
import datetime
import logging
import subprocess
from pathlib import Path

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)


class RegexPath:

    #: finds all groups within a ${GROUP}
    pattern = re.compile('(?<=\${)([^${}]*)(?=})')

    def __init__(self, path):
        if not isinstance(path, Path):
            path = Path(path)
        self._raw = path.expanduser().resolve()
        self.vars = re.findall(self.pattern, str(path))

    def replace_from(self, match):
        path = str(self._raw)
        if match:
            for k, v in match.groupdict().items():
                path = path.replace(f'${{{k}}}', v)
        return Path(path)


def copy_files(filename, comment='#'):
    logger.info(f'>>> Copying files from {filename}')
    here = Path.cwd()
    with open(filename, 'r') as f:
        contents = f.readlines()

    lines = [x.split(comment)[0].strip() for x in contents]
    lines = [x.split() for x in lines if x]
    for line in lines:
        unix_pattern = Path(line[0]).expanduser().resolve()
        try:
            dest = line[1]
        except IndexError:
            dest = here
        try:
            regex = line[2]
        except IndexError:
            pattern = None
        else:
            pattern = re.compile(regex)

        dest = RegexPath(dest)
        files = glob.glob(str(unix_pattern), recursive=True)
        for file in files:
            if pattern:
                matches = re.search(pattern, file)
                dest_dir = dest.replace_from(matches)
            else:
                dest_dir = dest._raw
            dest_dir.mkdir(parents=True, exist_ok=True)
            file_path = Path(file)
            abs_dest = dest_dir / file_path.name

            if file_path.is_file():
                shutil.copyfile(file_path, abs_dest)
            else:
                if abs_dest.exists():
                    shutil.rmtree(abs_dest)
                shutil.copytree(file_path, abs_dest)
            logger.debug(f'Copied {file} to {abs_dest}')


def copy_conda_envs(conda_root='~/anaconda3/'):
    logger.info(f'>>> Saving conda environments from {conda_root}')
    root = Path(conda_root).expanduser().resolve()
    envs_dir = root / 'envs'
    conda_exe = root / 'bin' / 'conda'
    envs = sorted([env for env in envs_dir.glob('*/')
                   if not env.name.startswith('.')])
    for env in envs:
        name = env.name
        env_dir = Path('conda') / name
        env_dir.mkdir(parents=True, exist_ok=True)
        env_yml = env_dir / 'environment.yml'
        fh = env_yml.open(mode='w')
        cmd = [str(conda_exe), 'env', 'export', '--name', name, '--no-builds']
        proc = subprocess.run(cmd, stdout=fh)
        fh.close()
        logger.debug(' '.join(cmd) + f' > {str(env_yml)}')


def push_to_git():
    logger.info('=== Pushing to git ===\n')
    git_dir = Path(__file__).parent.resolve()
    git_exe = '/usr/local/bin/git'
    add = [git_exe, 'add', '.']
    commit = [git_exe, 'commit', '-m', 'daily update from script']
    push = [git_exe, 'push', 'origin', 'backups']
    subprocess.run(add, cwd=git_dir)
    subprocess.run(commit, cwd=git_dir)
    subprocess.run(push, cwd=git_dir)


if __name__ == '__main__':
    date_fmt = '%d/%m/%Y %H:%M:%S %Z'
    fh = logging.FileHandler('.log')
    fh.setLevel(logging.DEBUG)
    logger.addHandler(fh)
    start_time = datetime.datetime.now()
    logger.info(f'=== Started {start_time.strftime(date_fmt)} ===')
    copy_files('.paths')
    copy_conda_envs()
    end_time = datetime.datetime.now()
    logger.info(f'=== Finished {end_time.strftime(date_fmt)} ===')
    push_to_git()

