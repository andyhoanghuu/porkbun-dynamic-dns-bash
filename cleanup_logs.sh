#!/bin/bash

# Thư mục chứa các file log
LOG_DIR="logs"

# Di chuyển đến thư mục logs
cd "$LOG_DIR" || exit 1

# Giữ lại 3 ngày gần nhất
find . -type f -name 'log_*.txt' | sort | head -n -3 | xargs -r rm -f
