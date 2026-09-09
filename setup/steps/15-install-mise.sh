#!/usr/bin/env bash
step_check() { return 1; }

step_run() {
  bash "$SETUP_ROOT/lib/mise-latest.sh"
}
