resource "aws_instance" "tkg" {
  ami           = "ami-08ca3fed11864d6bb"
  instance_type = lookup(var.awsprops, "itype") 
  associate_public_ip_address = true
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = ["${aws_security_group.mywebsecurity.id}"]
  key_name = lookup(var.awsprops, "keyname") 
  availability_zone = lookup(var.awsprops, "availability_zone") 

  connection {
      host        = aws_instance.tkg.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("/Users/sauera/Downloads/terraform/sauer-key.pem")}"
    
    }


  provisioner "file" {
    source      = "prep.sh"
    destination = "/home/ubuntu/prep.sh"
   }

  provisioner "file" {
    source      = "terraform.tfstate"
    destination = "/home/ubuntu/terraform.tfstate"
   }
  provisioner "file" {
    source      = "vpc.intiator.sh"
    destination = "/home/ubuntu/vpc.intiator.sh" 

   }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 prep.sh",
      "sudo chmod 777 vpc.intiator.sh",
      "sudo ./vpc.intiator.sh",      
      "sudo ./prep.sh",
    ]
  } 


tags = {
    Name = "tkg"
  }

  root_block_device {
    volume_size = "30"
  }

}


output "ec2instance" {
  value = aws_instance.tkg.public_ip
}
