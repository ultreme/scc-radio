#!/usr/bin/env python


import os


def main():
    for root, dirs, files in os.walk("playlists", topdown=False):
        for name in files:
            # FIXME: read ID3 tags
            print(os.path.join(root, name))



if __name__ == '__main__':
    main()
