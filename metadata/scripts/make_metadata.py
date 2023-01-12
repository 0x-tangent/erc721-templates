#!/usr/bin/env python

import argparse
import json
import os

def read_csv(filepath: str) -> list[list[str]]:
    """read csv file and return list of lists

    args:
        filepath (str): path to csv file

    returns:
        list[list[str]]: list of lists
    """
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"file not found: {filepath}")

    with open(filepath, "r") as f:
        lines = f.readlines()

    return [line.strip().split(",") for line in lines]

def generate_metadata(name: str, description: str, base_uri: str, attributes: list[list[str]]) -> int:
    """generate metadata file for ERC721 collection

    args:
        name (str): name of the project #{tokenId}
        description (str): description of the project
        base_uri (str): tokenURI (to ipfs/arweave folder or cloud storage endpoint)
        attributes (list[list[str]]): list of attributes for each token from csv
    """

    # create metadata directory
    if not os.path.exists("build"):
        os.mkdir("build")

    attribute_names = attributes.pop(0)
    attribute_count = len(attribute_names)

    file_count = 0

    def read_attributes(attrs: list[str]):
        if (c := len(attrs)) != attribute_count:
            raise ValueError(f'invalid attributes, expected {attribute_count} but got {c}: {attrs}')
        return [{'trait_type': attribute_names[i], 'value': attrs[i]} for i in range(c)]

    # generate metadata for each token
    for i, nft in enumerate(attributes):
        metadata = {
            'name': f'name #{i}',
            'description': description,
            'image': f'{base_uri}/{i}.png',
            'attributes': read_attributes(nft)
        }
        with open(f'build/{i}.json', 'w') as f:
            f.write(json.dumps(metadata))
            file_count += 1

    return file_count


example = '''
{
    "name": "My NFT #0",
    "description": "example project\n\nfor making erc721s",
    "image": "IPFS | ARWEAVE | API endpoint for the image",
    "edition": 0,
    "attributes": [
        {
            "trait_type": "Background",
            "value": "White"
        },
        {
            "trait_type": "Face",
            "value": "Smile"
        },
        {
            "trait_type": "Eyes",
            "value": "Sunglasses"
        },
        {
            "trait_type": "Shirt",
            "value": "Black"
        }
    ]
}
'''


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