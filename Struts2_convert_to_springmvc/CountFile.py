import com.liufq.DetectEmptyConstructor as detect
import sys

count = 0;


def count_file(root, file):
    global count
    count += 1;


if __name__ == '__main__':
    if not len(sys.argv) > 1:
        print("usage：python DetectEmptyConstructor.py path1 path2...")
        print("ps: please use python version 3 or above")
    detect.iterate_files(sys.argv[1:], count_file)
    print(count)
