variable "DANTTO4K_VERSIONS" {
  default = [
    "1.0.0-rc9",
    "1.0.0-rc8"
  ]
  type    = list(string)
}

variable "DANTTO4K_LATEST_VERSION" {
  default = "1.0.0-rc8"
  type    = string
}

variable "TSDUCK_VERSION" {
  default = "3.41-4299"
  type    = string
}

variable "DANTTO4K_IMAGE" {
  default = "ghcr.io/till0196/dantto4k"
  type    = string
}

variable "DMIRAKURUN_IMAGE" {
  default = "ghcr.io/till0196/dmirakurun"
  type    = string
}

variable "DMIRAKURUN_REPO" {
  default = "https://github.com/Till0196/DMirakurun.git"
  type    = string
}

variable "DMIRAKURUN_BRANCH" {
  default = "master"
  type    = string
}

variable "DEPGSTATION_IMAGE" {
  default = "ghcr.io/till0196/depgstation"
  type    = string
}

variable "DEPGSTATION_REPO" {
  default = "https://github.com/nekohkr/DEPGStation.git"
  type    = string
}

variable "DEPGSTATION_BRANCH" {
  default = "master"
  type    = string
}

variable "BUILD_TIMESTAMP" {
  default = formatdate("YYYY-MM-DD-hhmm", timeadd(timestamp(), "9h"))
  type    = string
}

variable "BUILD_DANTTO4K" {
  default = true
  type    = bool
}

variable "BUILD_DMIRAKURUN_BASE" {
  default = true
  type    = bool
}

variable "BUILD_DEPGSTATION_BASE" {
  default = true
  type    = bool
}

# dantto4k image
target "dantto4k" {
  name  = "dantto4k-${replace(DANTTO4K_VERSION, ".", "-")}"
  matrix = {
    DANTTO4K_VERSION = DANTTO4K_VERSIONS
  }
  dockerfile = "dantto4k/Dockerfile"
  contexts = {
    src = "./dantto4k"
  }
  target = "release"
  tags   = [
    "${DANTTO4K_IMAGE}:${DANTTO4K_VERSION}",
    "${DANTTO4K_IMAGE}:${DANTTO4K_VERSION}-${BUILD_TIMESTAMP}",
    equal(DANTTO4K_VERSION, DANTTO4K_LATEST_VERSION) ? "${DANTTO4K_IMAGE}:latest" : ""
  ]
  args   = {
    DANTTO4K_VERSION = DANTTO4K_VERSION
    TSDUCK_VERSION = TSDUCK_VERSION
  }
}

# DMirakurun base image without dantto4k
target "dmirakurun-base" {
  dockerfile = "docker/Dockerfile"
  context = "${DMIRAKURUN_REPO}#${DMIRAKURUN_BRANCH}"
  tags = [
    "${DMIRAKURUN_IMAGE}:base",
    "${DMIRAKURUN_IMAGE}:base-${BUILD_TIMESTAMP}",
    "${DMIRAKURUN_IMAGE}:base-latest"
  ]
}

# DMirakurun without dantto4k
target "dmirakurun-without-dantto4k" {
  dockerfile = "dmirakurun/Dockerfile"
  contexts = {
    src = "./dmirakurun"
    "ghcr.io/till0196/dmirakurun:base" = BUILD_DMIRAKURUN_BASE ? "target:dmirakurun-base" : "docker-image://${DMIRAKURUN_IMAGE}:base"
  }
  target = "without-dnatto4k"
  tags = [
    "${DMIRAKURUN_IMAGE}:without-dantto4k",
    "${DMIRAKURUN_IMAGE}:without-dantto4k-${BUILD_TIMESTAMP}",
    "${DMIRAKURUN_IMAGE}:without-dantto4k-latest"
  ]
}

# DMirakurun with dantto4k
target "dmirakurun-with-dantto4k" {
  name = "dmirakurun-with-dantto4k-${replace(DANTTO4K_VERSION, ".", "-")}"
  matrix = {
    DANTTO4K_VERSION = DANTTO4K_VERSIONS
  }
  dockerfile = "dmirakurun/Dockerfile"
  contexts = {
    src = "./dmirakurun"
    "ghcr.io/till0196/dmirakurun:base" = BUILD_DMIRAKURUN_BASE ? "target:dmirakurun-base" : "docker-image://${DMIRAKURUN_IMAGE}:base"
    "ghcr.io/till0196/dantto4k" = BUILD_DANTTO4K ? "target:dantto4k-${replace(DANTTO4K_VERSION, ".", "-")}" : "docker-image://${DANTTO4K_IMAGE}:${DANTTO4K_VERSION}"
  }
  target = "with-dantto4k"
  tags = [
    "${DMIRAKURUN_IMAGE}:with-dantto4k",
    "${DMIRAKURUN_IMAGE}:with-dantto4k-${DANTTO4K_VERSION}-${BUILD_TIMESTAMP}",
    equal(DANTTO4K_VERSION, DANTTO4K_LATEST_VERSION) ? "${DMIRAKURUN_IMAGE}:latest" : "",
  ]
}

target "depgstation-base" {
  dockerfile = "Dockerfile.debian"
  context = "${DEPGSTATION_REPO}#${DEPGSTATION_BRANCH}"
  tags = [
    "${DEPGSTATION_IMAGE}:base",
    "${DEPGSTATION_IMAGE}:base-${BUILD_TIMESTAMP}",
    "${DEPGSTATION_IMAGE}:base-latest"
  ]
}

target "depgstation" {
  dockerfile = "dmirakurun/Dockerfile"
  contexts = {
    src = "./depgstation"
    "ghcr.io/till0196/depgstation:base" = BUILD_DEPGSTATION_BASE ? "target:depgstation-base" : "docker-image://${DEPGSTATION_IMAGE}:base"
  }
  tags = [
    "${DMIRAKURUN_IMAGE}:${BUILD_TIMESTAMP}",
    "${DMIRAKURUN_IMAGE}:latest"
  ]
}

# Group targets
group "default" {
  targets = ["dmirakurun-with-dantto4k", "depgstation"]
}

group "all" {
  targets = [
    "dantto4k",
    "dmirakurun-base",
    "dmirakurun-without-dantto4k",
    "dmirakurun-with-dantto4k",
    "depgstation-base",
    "depgstation"
  ]
}
