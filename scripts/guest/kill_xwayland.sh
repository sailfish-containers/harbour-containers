#!/bin/bash
kill $(ps aux | grep '[X]wayland' | awk '{print $2}')
