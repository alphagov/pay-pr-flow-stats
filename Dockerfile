FROM ruby:2.6-alpine

COPY . /pay-pr-flow-stats

WORKDIR /pay-pr-flow-stats

RUN ["bundle", "install"]
