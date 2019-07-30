#!/bin/sh
export PGPASSWORD='postgres'; 
export PGOPTIONS='--search_path=mimiciii';

# Extracting the PU chartevents
psql -U postgres -d mimic -f extract-icd9-features.sql | gzip -9 > data/icd9-features.gz;