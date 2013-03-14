from __future__ import absolute_import, division, print_function, unicode_literals

import subprocess
import tempfile


OK = 0
CANCEL = 255


def escape(input):
    return input.replace('"', r'\"')


class Dialog(object):
    def __init__(self, backtitle):
        self.backtitle = backtitle

    def __run(self, cmd_args):
        cmd = """dialog --backtitle "{}" {}""".format(escape(self.backtitle), cmd_args)
        p = subprocess.Popen(cmd, stderr=subprocess.PIPE, shell=True)
        out, err = p.communicate()
        exit_code = p.returncode
        return (exit_code, err)

    def msg_box(self, text, title="", width=50, height=10):
        dialog_args = """--title "{title}" --msgbox "{text}" {height} {width}""".format(
            title=escape(title), text=escape(text), width=width, height=height)
        return self.__run(dialog_args)

    def input_box(self, prompt, value="", title="", width=50, height=10):
        dialog_args = """--title "{title}" --inputbox "{text}" {height} {width} {value}""".format(
            title=escape(title), text=escape(prompt), width=width, height=height, value=value)
        return self.__run(dialog_args)

    def password_box(self, prompt, value="", title="", width=50, height=10):
        dialog_args = """--title "{title}" --passwordbox "{text}" {height} {width} {value}""".format(
            title=escape(title), text=escape(prompt), width=width, height=height, value=value)
        return self.__run(dialog_args)

    def edit_box(self, file_name, title="", width=70, height=20):
        if not file_name:
            # auto-deleted on GC
            temp_file = tempfile.NamedTemporaryFile()
            file_name = temp_file.name

        dialog_args = """--title "{title}" --editbox "{file_name}" {height} {width}""".format(
            title=escape(title), file_name=file_name, width=width, height=height)
        return self.__run(dialog_args)

    def text_box(self, file_name, title="", width=70, height=20):
        dialog_args = """--title "{title}" --textbox "{file_name}" {height} {width}""".format(
            title=title, file_name=file_name, width=width, height=height)
        return self.__run(dialog_args)
