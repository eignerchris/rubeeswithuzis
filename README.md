# rubeeswithuzis

Author: Chris Eigner

## Description
Rudimentary Ruby implementaion of beeswithmachineguns (https://github.com/newsapps/beeswithmachineguns)

Spins up micro EC2 instances and blasts the supplied URL with requests.

Results from each instance are concatonated and written to results.txt

## Notes
Requires ~/.fog to exist. First run of fog binary will spit out sample .fog, or the sample can be found here: https://github.com/geemus/fog/blob/master/lib/fog/core/errors.rb

Assumes you have public key named id_rsa in ~/.ssh

Does NOT divide requests among all instances like beeswithmachineguns. If you run with "-s 4 -c 10", this will run 10 concurrent requests on each instance, creating a total of 40 concurrent requests at the server.

## Usage
rubeeswithuzis -s 4 -n 1000 -c 10 -u http://someurl.com/
