# Variables for IAM Management Module
# Separate from VPC infrastructure as recommended in C3.md

variable "region" {
  type        = string
  description = "AWS region for IAM resources"
  default     = "us-east-1"
}

variable "github_token" {
  type        = string
  description = "GitHub personal access token for repository management"
  sensitive   = true
}

variable "github_organization" {
  type        = string
  description = "GitHub organization or username"
  default     = "EpitechPGE45-2025"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository name"
  default     = "G-CLO-900-PAR-9-1-infraascode-4"
}

variable "team_members" {
  type = list(object({
    username        = string
    display_name    = string
    email           = string
    github_username = string
  }))
  description = "List of team members with their details"
  default = [
    {
      username        = "student1-team4"
      display_name    = "Corentin Levet"
      email           = "corentin.levet@epitech.eu"
      github_username = "corentinlevet"
    },
    {
      username        = "student2-team4"
      display_name    = "Hugo Grisel"
      email           = "hugo.grisel@epitech.eu"
      github_username = "GriselHugo"
    },
    {
      username        = "student3-team4"
      display_name    = "Gwendoline Vanelle"
      email           = "gwendoline.vanelle@epitech.eu"
      github_username = "gwen24112003"
    },
    {
      username        = "student4-team4"
      display_name    = "Romain Oeil"
      email           = "romain.oeil@epitech.eu"
      github_username = "RomainOeil"
    }
  ]
}

variable "instructor_pgp_key" {
  type        = string
  description = "Instructor's GPG public key for credential encryption"
  default     = <<-EOT
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBGjVjBYBEACrUUP5XMVE6TqLPKjSWChtYpETzDT+wAojujnFG2LMPggJC+dL
TJrUnu2JOV6uejSbcPbQXCCXcPKOIPi0LAtAW3NBCjRlrlZ81YpsiIo9lhJekjP7
V++LNcwduoy35sl1icFnpyd90imWEJ0Wk+AxxALyxTBiaMvoiO36vuZ8M5QXQkB4
6xBJ7xChwvT2ysruwBL1iw6UUCTtVRTFb3OLVIyK7LI4HAF2s88w2MC1vXKHrPpR
qlYQInPpW+qXCICLhsqIIVjRAprbqfqtsOrEMQAQ8gUrjvDHXRbQILNRhe9ghG+m
UADfRj7gPmep+m19WQDCPGFNjwUH7KdU+PiJfG8KnFzgZ7mfmV4iTSw3TiCHyh2h
XXka3wEGlo49wR3gWZskMANg/Lpbslw4zF50fI4uGu2t/ERuyf6y6ZWxKY5INngw
foPrbCzPOHvSCB3TlzCQeLKJIuqtVgvo3nh6Ce4u4XeOFAEaPfW01KXl+K/uYFgF
RUovPyzqAefMvdeifrOr+A7OJYvrw9L1MoZaFGHFHwBHsKLVrxhviTvu1BYEw9Qo
JXshXLT7ziks/UIUQSInJWEhUCcxR+YKdNj0oqshDTL8fzoSThRRwZAPY9ciq8Y9
SXs97YNGB1f/DUVNmQs3Uw/vtB5PuchLHpzLDGYGN4FcAl5QtClM8KjyIwARAQAB
tEdKw6lyw6ltaWUgSkFPVUVOIChHUEcga2V5IGZvciBFcGl0ZWNoIElBQyBtb2R1
bGUpIDxqZXJlbWllQGpqYW91ZW4uY29tPokCTgQTAQoAOBYhBJhLBQgHtKya5aVJ
FEKylOmKdzW4BQJo1YwWAhsDBQsJCAcCBhUKCQgLAgQWAgMBAh4BAheAAAoJEEKy
lOmKdzW4eUkP/00kJjBDLlNK++VU1tLg9K+COpTg4yeAKHgjJDo252GdACTvCC3K
xZAh8uFXQLO4WefawgXydfqXSm+T2s4i6GD3CAq5+P2AtxnPGALU+upjz2Xrxvda
csX2VIe7LVlyO+inVO1Xw0X6joMXHO5wj+k9Lj/+r+jDvXin8itmPZu9bQj6CUyb
ztmW58L/vUzxg2YuoW92/q9yF365Av9R32VspGn1e9oF7VL+W3j4lMuMXOKTHQK4
3lttLnmaVsu+V5swU3FVCLyppAAtO/q4KD4vvvoEd0BmDZu1dyiYH9/SXnzpqfMy
m+FVH7ZyvpvUSpljX9AR+8roZ+IQlai66OBFMp40EIVgKzAoSyyvpKiyJIPm0UuK
Ey0R7ZYgUS1a0kq1WD8eZLKuardbedushbekinE7jCh/sQ2AlbXwQ6rR4Q6IgoKo
+FALD8vRB/tuDikPlgifJSGJ6eGO7twm8j0MbyPfBFxUwCIyTynN/bhl7QphOsAJ
4H+lOH9PsdYwD73i1QT2+0HPvIMNgZXuG6bipolxMBH5/A2V8tjpztoIw+jMdjnj
rQQnt0eB5KUItHBwrOHETAuJQboxlQ7CFPP1lY29/OjyJTye5O5Hf4llk+hHwNGI
FDkBF8HjhmDDAst182rJoYiT+HTx6x/2WeUmVGiAN2mFT7yFl1vEXonRuQINBGjV
jBYBEACv1rNYDmtbD7EKmq/0SoSyGkf/MoDBD48BvnvCEuIbwEJA89dKqlfUps+c
GR9un4UMh9eD3Ey3IGBuppoFH08e9iXgT96bFmhO7WqgHLedQt3RcDVlM1HOEkoA
hHWNFNgwUXU5sTyOgg/UAQhFkH0yq1VLCKiaf98uCzGRYwXLrge2a9+Elq321HQq
mqxNbGnIFymyW6T3cYEhcqmGH0pdAWNLKliviwa1VaHyzl1vitK+qN25DIjP2JEe
4D1KvU6E/8cTojsWCs3gUxGofNgpE3FVDZcXKELSfuPSbDa8gslNJC0WC189okZ3
d+M0/wu348H3N7fAV69Gryi/pHaCWVKwm0bRrpDzf888wPkhWw6U+Z26enB/Zic1
3uTd7kmxVQDiNbc9mTGAZnW88xvZ6hmWnR/HbU6LQ3JnJwcQbe08aaNcDzFUhX5O
Amejz86DOTX4NVdnO+jrTcKWs14CtdihpE93GGz/cOEDjqMVKDY9m+W7Ag6sS569
cY2vPdVAF94ArfwFJxsexGFn3WOpqdBZWXT3vx38ItdbviEzKl1FJPEafLqpcMPc
MCONJFqxcg27LST4lLZH4sxyr+z0tn7TfaImFrVds82GM0FHHvgickL9q3LYVs5+
MJLiJLdKuvTjpq1dEQTM78xhCESESDqKUqbyAzgO/bSQB2C6/wARAQABiQI2BBgB
CgAgFiEEmEsFCAe0rJrlpUkUQrKU6Yp3NbgFAmjVjBYCGwwACgkQQrKU6Yp3Nbij
8Q/+OySSeaC/qlVz/p6KNaZXW1iCsZ1CLFtGunoIGoZLkbZx809bkZoUxE4B16mt
5YrQXc5LW92fejPupkNohWETpt8Kx5bnCKDW8RyYOOs0KmH+kZt3cVp02kod3ckN
lGLuB4qdVJ4JH30Pabb4qwpcfMr+/s/lHt4R7XBADo7pt8CYfXcg5vztTUgcEYOh
01T7sXtAYv9WI+XWIhoK68bRbh5BFKMmifc+4P0ZQzi+JHdybVmQNMo58oWIZEb5
hf82cW5Aitb9vtd/LQyM3NyLVebbuNP2Sj/5My/xYIviyhHfiNnOCUOUWAmNTpNV
AYcl0LbmYEURJYEopBzLRQl1XQ3cozpBzmHKdjvEUXXGAztshCypmZ5zVGg1Y0pD
ReUoUr1YNZpF2mmmo9OhXw5fLjiuAyqH6h7FqepmRa/oKreFkFtPaGPQjRXpnpeJ
R/0tdc4jThrZOH1fl6xlQzOF+7Uv4YTAmkdkdzCHWrXTWNAYflCEMfOsIfjpaGZx
5uGfYFEWtjM4SVw6AW/2phYmLqNHSkNvQ1m35gCCxBZ7SLyGGXWV0ajGWutzlaqZ
0mEiebhzs2QEVWaPqUzthOEi3/+nCPD3cTcAunT3aRacDOiRlRR8Bwxp4mb3cxtj
h4VIu6KuOR3Eg1UROfwbedSkTqFlnOsNU4lNrdO8hSdr1oA=
=dciJ
-----END PGP PUBLIC KEY BLOCK-----
EOT
}
