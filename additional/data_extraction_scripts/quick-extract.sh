#!/bin/sh
export PGPASSWORD='postgres'; 
export PGOPTIONS='--search_path=mimiciii';

# Extracting the data
psql -U postgres -d mimic -f extract-bp.sql | gzip -9 > data/raw_data_20180530/bpchartevents.gz;