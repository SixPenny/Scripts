import os
import re
import sys


def iterate_files(paths, funcs):
    detected_files = []
    if not paths:
        return
    to_detect_dirs = paths
    for path in to_detect_dirs:
        list_dirs = os.walk(os.path.normpath(path))
        for root, dirs, files in list_dirs:
            for file in files:
                detected = funcs(root, file)
                if detected:
                    detected_files.append(detected)
            for appenddir in dirs:
                to_detect_dirs.append(appenddir)
    return detected_files


def detect_empty_constructor(root, file):
    if not file.endswith(".java"):
        return
    full_path = os.path.join(root, file)
    file_name = file[:-5]
    pattern = re.compile(r"public\s*" + file_name + r"\s*\(\s*\)")
    with open(full_path, encoding='utf-8') as open_file:
        for line in open_file:
            try:
                line.index(file_name)
                if pattern.search(line):
                    return file_name
            except ValueError:
                pass


def detect_class(classes):
    print(classes)

    def inner_detect(root, file):
        if not file.endswith(".java"):
            return
        full_path = os.path.join(root, file)
        with open(full_path, encoding='utf-8') as open_file:
            for line in open_file:
                try:
                    for clazz in classes:
                        line.index(clazz + ".class")
                        return full_path
                except ValueError:
                    pass

    return inner_detect


if __name__ == '__main__':
    if not len(sys.argv) > 1:
        print("usage：python DetectEmptyConstructor.py path1 path2...")
        print("ps: please use python version 3 or above")
    detected_files_name = iterate_files(sys.argv[1:], detect_empty_constructor)
    detected_class_use = iterate_files(sys.argv[1:], detect_class(detected_files_name))
    for filesss in detected_class_use:
        print(filesss)
        # retest()
