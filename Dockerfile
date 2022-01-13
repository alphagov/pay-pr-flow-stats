FROM ruby:3.1.0-alpine

COPY . /pay-pr-flow-stats

WORKDIR /pay-pr-flow-stats

RUN ["bundle", "install"]
