"""
        COPYRIGHT (c) 2019-2023 by Featuremine Corporation.

        This Source Code Form is subject to the terms of the Mozilla Public
        License, v. 2.0. If a copy of the MPL was not distributed with this
        file, You can obtain one at https://mozilla.org/MPL/2.0/.
"""

import argparse
import os
import pandoc
import shutil
import subprocess
import urllib


def build_table_of_contents(ast_1):
    table_of_contents = []
    for i in ast_1:
        if isinstance(i, pandoc.types.Header):
            p = table_of_contents
            for _ in range(1, i[0]):
                assert len(p) != 0, 'document headers incorrect'
                p = p[len(p) - 1][2]
            p.append((
                i[1][0],
                i[2],
                []
            ))

    return table_of_contents

def compile(ast):
    ast_1 = ast[1]
    mod = []

    def expand_sublist(list):
        items = []
        for link, text, sublist in list:
            link_element = pandoc.types.Plain([pandoc.types.Link(('', [], []), text, (f'#{link}', ''))])
            if len(sublist) > 0:
                items.append([
                    link_element,
                    expand_sublist(sublist)
                ])
            else:
                items.append([
                    link_element
                ])

        return pandoc.types.BulletList(items)

    for i in ast_1:
        if isinstance(i, pandoc.types.RawBlock):
            format = i[0]
            if isinstance(format, pandoc.types.Format):
                if format[0] == 'html':
                    if i[1].strip() == '<!--TOC-->':
                        toc = build_table_of_contents(ast_1)
                        mod.append(expand_sublist(toc))
                        continue
        mod.append(i)

    return mod


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--builddir", help="build directory", required=True)
    parser.add_argument("--srcdir", help="source directory", required=True)
    parser.add_argument("--depfile", help="DEPFILE file path", required=True)
    parser.add_argument("--target", help="target name", required=True)
    parser.add_argument("--htmloutput", help="html output name", required=True)
    parser.add_argument("--mdoutput", help="markdown output name", required=True)
    parser.add_argument("--deptarget", help="depfile target output name", required=True)
    parser.add_argument("--title", help="title", required=True)
    parser.add_argument("--cmake", help="cmake executable", required=True)
    args = parser.parse_args()

    dependencies = []
    tar_html_files = []
    tar_md_files = []
    tar_common_files = []

    stylepath = os.path.join(os.path.dirname(__file__), 'water.min.css')
    dependencies.append(stylepath)
    with open(stylepath, 'r', encoding='utf8') as stylefile:
        style = stylefile.read()

    to_compile = [
        os.path.abspath(os.path.join(args.srcdir, 'README.md'))
    ]
    compiled = set()

    def compile_md(src):
        if src in compiled:
            return
        compiled.add(src)
        dependencies.append(src)

        src_noext = os.path.splitext(src)[0]
        output_path_noext = os.path.join(args.builddir, os.path.relpath(src_noext, start=args.srcdir))

        if os.path.basename(output_path_noext) != 'README':
            output_path_html = f'{output_path_noext}.html'
        else:
            output_path_html = f'{os.path.dirname(output_path_noext)}/index.html'

        output_path_md = f'{output_path_noext}.md'
        os.makedirs(os.path.dirname(output_path_html), exist_ok=True)

        with open(src, 'rb') as f:
            s = f.read().decode("utf-8")
            ast = pandoc.read(source=s, format='gfm')

        ast = compile(ast)

        for i in pandoc.iter(ast):
            if isinstance(i, pandoc.types.Image):
                image_src = os.path.join(os.path.dirname(src), i[2][0])
                dependencies.append(image_src)

                image_dst = os.path.join(args.builddir, os.path.relpath(image_src, start=args.srcdir))
                tar_common_files.append(image_dst)

                shutil.copyfile(image_src, image_dst)

            elif isinstance(i, pandoc.types.Link) and urllib.parse.urlparse(i[2][0]).scheme == "":
                linkfile = i[2][0].split('#')[0]
                linkpath = os.path.abspath(os.path.join(os.path.dirname(src), linkfile))
                if linkfile != '' and not linkpath in compiled:
                    to_compile.append(linkpath)

        md = pandoc.write(doc=ast, format='gfm')

        with open(output_path_md, 'w', encoding='utf8') as outfile:
            outfile.write(md)

        for i in pandoc.iter(ast):
            if isinstance(i, pandoc.types.Link) and urllib.parse.urlparse(i[2][0]).scheme == "":
                linkfile = i[2][0].split('#')[0]
                if linkfile != '':
                    i[2] = (f'{os.path.splitext(i[2][0])[0]}.html', i[2][1])

        html = pandoc.write(doc=ast, format='html', options=[
            "--ascii",
            "--wrap=none",
        ])

        with open(output_path_html, 'w', encoding='utf8') as outfile:
            outfile.write(f'''<!DOCTYPE html>\n<html><head><title>{args.title}</title><style>{style}</style></head><body>''')
            outfile.write(html)
            outfile.write('''</body></html>''')

        tar_html_files.append(output_path_html)
        tar_md_files.append(output_path_md)

    for src in to_compile:
        compile_md(src)

    os.makedirs(os.path.dirname(args.htmloutput), exist_ok=True)
    proc = subprocess.Popen([args.cmake, '-E', 'tar', 'czvf', args.htmloutput] + tar_html_files + tar_common_files, cwd=args.builddir)
    proc.wait()
    proc.poll()
    assert proc.returncode == 0

    os.makedirs(os.path.dirname(args.mdoutput), exist_ok=True)
    proc = subprocess.Popen([args.cmake, '-E', 'tar', 'czvf', args.mdoutput] + tar_md_files + tar_common_files, cwd=args.builddir)
    proc.wait()
    proc.poll()
    assert proc.returncode == 0

    with open(args.depfile, 'w') as out:
        out.write(f'{args.deptarget}: {stylepath}')
        for d in dependencies:
            p = os.path.abspath(d)
            out.write(f' {p}')
        out.write('\n')