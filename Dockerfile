FROM ruby:3.1-alpine

COPY . /pay-pr-flow-stats

WORKDIR /pay-pr-flow-stats

RUN ["bundle", "install"]
