#!/bin/bash
#SBATCH --job-name=blastn_parallel
#SBATCH --output=blastn_parallel_output_%j.txt
#SBATCH --error=blastn_parallel_error_%j.txt
#SBATCH --partition=Orion
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --mem=120G
#SBATCH --time=48:00:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=cbrabble@uncc.edu

# Load modules
module load blast/2.15.0+
module load parallel

# Move to working directory
cd /scratch/cbrabble/transcriptome

# Step 1: Split sequences.fasta into smaller chunks
mkdir -p chunks
csplit -z -f chunks/seq_ -b '%03d.fasta' sequences.fasta '/^>/' '{*}'

# Step 2: Define the BLAST command for a single file
blast_one() {
  infile=$1
  outfile=${infile/.fasta/.out}
  blastn -query "$infile" \
    -db /scratch/cbrabble/transcriptome/blastdb/refseq_rna \
    -evalue 1e-5 \
    -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore stitle" \
    -max_target_seqs 1 \
    -max_hsps 1 \
    -out "$outfile"
}

export -f blast_one

# Step 3: Run in parallel using 4 parallel jobs
parallel -j 4 blast_one ::: chunks/*.fasta

# Step 4: Combine results
cat chunks/*.out > combined_blastn_results.txt

echo "BLASTn parallel job completed."
