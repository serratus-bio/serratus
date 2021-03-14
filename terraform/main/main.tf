///////////////////////////////////////////////////////////
// SERRATUS MAIN TERRAFORM CONFIG
///////////////////////////////////////////////////////////
// VARIABLES ##############################

variable "aws_region" {
  type    = string
  default = "us-east-1"
  // ALWAYS RUN SERRATUS ON US-EAST-1
  // If you don't then you will incur egress
  // charges from S3/SRA. Export your data later
}

variable "dl_size" {
  type        = number
  default     = 0
  description = "Default number of downloader nodes (ASG)"
}

variable "align_size" {
  type        = number
  default     = 0
  description = "Default number of aligner nodes (ASG)"
}

variable "dev_cidrs" {
  type = set(string)
}

variable "key_name" {
  description = "Name of the previously created EC2 key pair, for SSH access"
  type        = string
}

variable "dockerhub_account" {
  type        = string
  description = "Dockerhub account name, where images will be pulled from"
}

variable "scheduler_port" {
  type    = number
  default = 8000
}

variable "output_bucket" {
  type = string
}

<<<<<<< HEAD
//variable "metrics_ip" {
//  type = string
//}
=======
variable "metrics_ip" {
  type = string
}
>>>>>>> d0fff74d593fc0da9cf5adc7da41fbd26498cefc

// PROVIDER/AWS ##############################
provider "aws" {
  version = "~> 2.49"
  region  = var.aws_region
}

provider "local" {
  version = "~> 1.4"
}

resource "aws_security_group" "internal" {
  name = "serratus-internal"
  ingress {
    # Allow all internal traffic between workers
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  ingress {
    # Allow dev SSH access from a minimal IP range
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.dev_cidrs
  }
  egress {
    # Required to download docker images and yum-update.
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// MODULES ##############################

// Working S3 storage for Serratus
module "work_bucket" {
  source = "../bucket"

  prefixes = ["fq-blocks", "bam-blocks", "out"]
}

// Cluster scheduler and task manager
module "scheduler" {
  source = "../scheduler"

  security_group_ids = [aws_security_group.internal.id]
  key_name           = var.key_name
<<<<<<< HEAD
  instance_type      = "r5.2xlarge"
  dockerhub_account  = var.dockerhub_account
  scheduler_port     = var.scheduler_port

  //# https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server
  //pg_shared_buffers  = "2GB" # 1/4 of RAM
  //pg_effective_cache = "6GB" # 3/4 of RAM
=======
  instance_type      = "m5.large"
  dockerhub_account  = var.dockerhub_account
  scheduler_port     = var.scheduler_port

  # https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server
  pg_shared_buffers  = "2GB" # 1/4 of RAM
  pg_effective_cache = "6GB" # 3/4 of RAM
>>>>>>> d0fff74d593fc0da9cf5adc7da41fbd26498cefc
}

// Cluster monitor
module "monitoring" {
  source = "../monitoring"

  security_group_ids = [aws_security_group.internal.id]
  key_name           = var.key_name
  scheduler_ip       = module.scheduler.private_ip
<<<<<<< HEAD
  //metrics_ip         = var.metrics_ip
=======
  metrics_ip         = var.metrics_ip
>>>>>>> d0fff74d593fc0da9cf5adc7da41fbd26498cefc
  dockerhub_account  = var.dockerhub_account
  instance_type      = "r5.xlarge"
}

// Serratus-dl
module "download" {
  source = "../worker"

  desired_size = 0
  max_size     = 5000

  dev_cidrs          = var.dev_cidrs
  security_group_ids = [aws_security_group.internal.id]

  instance_type = "r5.xlarge" // Mitigate the memory leak in fastq-dump
<<<<<<< HEAD
  volume_size   = 150         // Mitigate the storage leak in fastq-dump
  spot_price    = 0.12
=======
  volume_size   = 100         // Mitigate the storage leak in fastq-dump
  spot_price    = 0.10
>>>>>>> d0fff74d593fc0da9cf5adc7da41fbd26498cefc

  s3_bucket = module.work_bucket.name
  s3_prefix = "fq-blocks"

  image_name        = "serratus-dl"
  dockerhub_account = var.dockerhub_account
  key_name          = var.key_name
  scheduler         = "${module.scheduler.public_dns}:${var.scheduler_port}"
  options           = "-k ${module.work_bucket.name}"
}

// Serratus-align
module "align" {
  source = "../worker"

  desired_size       = 0
  max_size           = 10000
  dev_cidrs          = var.dev_cidrs
  security_group_ids = [aws_security_group.internal.id]
<<<<<<< HEAD
  instance_type      = "c5n.large" # c5.large
  volume_size        = 10
  spot_price         = 0.08
=======
  instance_type      = "c5.xlarge" # c5.large
  volume_size        = 12
  spot_price         = 0.10
>>>>>>> d0fff74d593fc0da9cf5adc7da41fbd26498cefc
  s3_bucket          = module.work_bucket.name
  s3_delete_prefix   = "fq-blocks"
  s3_prefix          = "bam-blocks"
  dockerhub_account  = var.dockerhub_account
  image_name         = "serratus-align"
  key_name           = var.key_name
  scheduler          = "${module.scheduler.public_dns}:${var.scheduler_port}"
  options            = "-k ${module.work_bucket.name} -a diamond"
}

//Serratus-merge
module "merge" {
  source = "../worker"
<<<<<<< HEAD
=======

>>>>>>> d0fff74d593fc0da9cf5adc7da41fbd26498cefc
  desired_size       = 0
  max_size           = 1500
  dev_cidrs          = var.dev_cidrs
  security_group_ids = [aws_security_group.internal.id]
  instance_type      = "c5.large"
  volume_size        = 150 // prevent disk overflow via samtools cat
  spot_price         = 0.05
  s3_bucket          = module.work_bucket.name
  s3_delete_prefix  = "bam-blocks"
  s3_prefix         = "out"
  dockerhub_account = var.dockerhub_account
  image_name        = "serratus-merge"
  key_name          = var.key_name
  scheduler         = "${module.scheduler.public_dns}:${var.scheduler_port}"
  options = "-k ${module.work_bucket.name} -b ${var.output_bucket}"
}

// RESOURCES ##############################
// Controller scripts created locally

resource "local_file" "hosts" {
  filename        = "${path.module}/serratus-hosts"
  file_permission = 0666
  content         = <<-EOF
    aws_monitor ${module.monitoring.public_dns}
    aws_scheduler ${module.scheduler.public_dns}
  EOF
}

resource "local_file" "create_tunnel" {
  filename        = "${path.module}/create_tunnels.sh"
  file_permission = 0777
  content         = <<-EOF
    #!/bin/bash
    set -eu
    ssh -Nf -L 3000:localhost:3000 -L 9090:localhost:9090 ec2-user@${module.monitoring.public_dns}
    ssh -Nf -L 8000:localhost:8000 -L 5432:localhost:5432 ec2-user@${module.scheduler.public_dns}
    echo "Tunnels created:"
    echo "    localhost:3000 = grafana"
    echo "    localhost:9090 = prometheus"
    echo "    localhost:5432 = postgres"
    echo "    localhost:8000 = scheduler"
  EOF
}

resource "local_file" "upload_sra" {
  filename        = "${path.module}/uploadSRA.sh"
  file_permission = 0777
  content         = <<-EOF
    #!/bin/bash
    # =====================================
    # Serratus - uploadSRA.sh
    # =====================================
    #
    # Usage: 
    # uploadSRA.sh <sraRunInfo.csv>
    #
    # script for uploading sraRunInfo.csv
    # files into Serratus in chunks and with
    # randomization of input to normalize load.
    # 
    set -eu

    # Config parameters -----------------------------
    # Input SRA file
    INPUT_SRA=$1

    # Chunk size for uploading
    SIZE=10000
    # -----------------------------------------------

    # Check that sraRunInfo was provided

    if [ -z "$INPUT_SRA" ]; then
        echo "Usage:"
        echo "  uploadSRA.sh <sraRunInfo.csv>"
        exit 1
    fi

    # Sript ==============================================

    # Descriptive parsing --------------------------------
    # Scheduler DNS: 
    echo "Loading SRARunInfo into scheduler "
    echo "  File: $INPUT_SRA"
    echo "  date: $(date)"
    echo "  wc  : $(wc -l $INPUT_SRA)"
    echo "  md5 : $(md5sum $INPUT_SRA)"
    echo ""
    echo ""

    # Extract header from csv input
    head -n1 $INPUT_SRA > sra.header.tmp

    # Split the input csv file into $SIZE chunks
    tail -n+2 $INPUT_SRA | split -d -l $SIZE - tmp.chunk

    # Re-header an sraRunInfo file for each chunk
    # with randomization of the data order
    # and upload to Serratus
    for CHUNK in $(ls tmp.chunk*); do

      cat  sra.header.tmp > "$CHUNK"_sraRunInfo.csv
      shuf $CHUNK >> "$CHUNK"_sraRunInfo.csv

      echo '--------------------------'
      echo $CHUNK
      wc -l "$CHUNK"_sraRunInfo.csv
      md5sum "$CHUNK"_sraRunInfo.csv
      
      # Upload to Serratus
      # via curl (localhost:8000)
      curl -s -X POST -T "$CHUNK"_sraRunInfo.csv \
        localhost:8000/jobs/add_sra_run_info/
      
      # Clean-up
      rm $CHUNK "$CHUNK"_sraRunInfo.csv
    done

    rm sra.header.tmp

    echo ""
    echo ""
    echo " uploadSRA complete."
  EOF
}

// OUTPUT ##############################
output "help" {
  value = <<-EOF
    Run ${local_file.create_tunnel.filename} to create SSH tunnels for all services.
  EOF
}

output "scheduler_dns" {
  value = module.scheduler.public_dns
}
output "scheduler_pg_password" {
  value = module.scheduler.pg_password
}

output "monitor_dns" {
  value = module.monitoring.public_dns
}

output "dl_asg_name" {
  value = module.download.asg_name
}
output "merge_asg_name" {
  value = module.merge.asg_name
}
output "align_asg_name" {
  value = module.align.asg_name
}
