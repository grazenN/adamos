#!/bin/bash
# Set focused window opacity
# Usage: opacity.sh 0.8  (for 80%)
transset -a "$1" 2>/dev/null || true
