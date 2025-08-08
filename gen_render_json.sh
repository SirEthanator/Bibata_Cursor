#!/bin/bash

jq -s 'reduce .[] as $item ({}; . * $item)' schemes/* > render.json

