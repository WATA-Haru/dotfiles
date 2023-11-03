#!/bin/bash

# if GIT_EMAIL set in docker-compose-yml set email and name
if [ -n "$GIT_EMAIL" ]; then
  git config --global user.email "$GIT_EMAIL"
fi

if [ -n "$GIT_NAME" ]; then
  git config --global user.name "$GIT_NAME"
fi

