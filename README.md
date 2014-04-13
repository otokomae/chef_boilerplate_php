Description
===========
This cookbook's goal is to provide the best and dead simple way to start new web application project based on php.

Containing following

| Category | Application |
| ------- | ---------- |
| Documentation Generator | sphinx |
| Class Document Generator | phpdoc |
| Package Manager | composer (not yet) |
| QA Tools | phpcs, phpunit, phpmd, phpdepend, phpcpd, phploc, phpcb |

Requirements
============
* Chef: 11.x+

Attributes
==========

Usage
=====

## How to use in a recipe
```
include_recipe 'boilerplate_php'
```
## Configuration
### Install sphinx, phpdoc into example.com
```
$ cat nodes/example.json
{
    "boilerplate_php": {
        "sphinx": {
            "host": "example.com",
            "path": "/sphinx"
        },
        "phpdoc": {
            "host": "example.com",
            "path": "/phpdoc"
        }
    }
}
```

### Stop installing specific applicaiton
e.g.) Stop installing sphinx
```
$ cat nodes/example.json
{
    "boilerplate": {
        "sphinx": false
    }
}
```

License and Authors
===================

* Author:: Jun Nishikawa <topaz2@m0n0m0n0.com>

* Copyright (C) 2014, Jun Nishikawa <topaz2@m0n0m0n0.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

