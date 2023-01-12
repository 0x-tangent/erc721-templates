#!/usr/bin/env python

import argparse
import lib
import os

def main():
    parser = argparse.ArgumentParser(description='Generate ERC721 metadata from csv file')
    parser.add_argument('-n', '--name', type=str, help='name of the project', required=True)
    parser.add_argument('-d', '--description', type=str, help='string description of the project or filepath to the description', required=True)
    parser.add_argument('-u', '--uri', type=str, help='tokenURI to ipfs/arweave folder or cloud storage endpoint (normalized to include a trailing slash)', required=True)
    parser.add_argument('-a', '--attributes', type=str, help='path to csv file', required=True)
    args = parser.parse_args()

    # if args.description is a file, read it
    name = args.name

    if os.path.exists(args.description):
        with open(args.description, 'r') as f:
            description = f.read()
    else:
        description = args.description

    uri = args.uri
    if not uri.endswith('/'):
        uri += '/'
    
    attributes = lib.read_csv(args.attributes)

    lib.generate_metadata(name, description, uri, attributes)


if __name__ == '__main__':
    main()