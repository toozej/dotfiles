#!/usr/bin/python3
# coding: utf-8
"""
Description of what this thing does

Module containing main and calling other modules

"""

import argparse
import sys


def count(args):
    """Default function for parser:
    count number of occurrences of phrase within text
    """


def main():
    """ Main function"""

    parser = argparse.ArgumentParser('useful help text \
                                     goes here')
    parser.add_argument('filename',
                        help='Filename of text file input',
                        nargs='*',
                        type=argparse.FileType('r'),
                        default=[sys.stdin])

    # set default function as count(), parse arguments and run count()
    parser.set_defaults(func=count)
    args = parser.parse_args()
    args.func(args)


if __name__ == '__main__':
    main()
