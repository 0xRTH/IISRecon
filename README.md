# IISRecon

This is bruteforce tool that fetch all IIS shortname thanks to SNS by Sw33tLie and try to bruteforce each one of them with a given wordlist.
If some of the found links are folders, it recusrively try to do the same.

## Usage
`./IISRecon.sh -u https://iis.server.com -o result.json`

Don't forget to set a wordlists folder in the script.

## Requirements
  - SNS by Sw33tLie - https://github.com/sw33tLie/sns
  - FFUF - https://github.com/ffuf/ffuf
  - and some wordlists to grep
