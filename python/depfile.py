"""
        COPYRIGHT (c) 2019-2023 by Featuremine Corporation.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""

import argparse
import os


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", help="target name", required=True)
    parser.add_argument("--sources", help="SOURCES.txt file path", required=True)
    parser.add_argument("--output", help="DEPFILE file path", required=True)
    args = parser.parse_args()
    with open(args.sources, 'r') as file:
        with open(args.output, 'w') as out:
            out.write(f'{args.target}:')
            for line in list(file):
                if line != 'setup.py':
                    p = os.path.abspath(line.strip())
                    out.write(f' {p}')
            out.write(f'\n')
