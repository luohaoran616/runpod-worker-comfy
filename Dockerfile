# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

# Change working directory to ComfyUI
WORKDIR /comfyui

ARG SKIP_DEFAULT_MODELS
# Download checkpoints/vae/LoRA to include in image.
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/checkpoints/sd_xl_base_1.0.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/vae/sdxl_vae.safetensors https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/vae/sdxl-vae-fp16-fix.safetensors https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/sdxl_vae.safetensors; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/checkpoints/juggernautXL_v8Rundiffusion.safetensors https://civitai.com/api/download/models/288982; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/checkpoints/albedobaseXL_v21.safetensors https://civitai.com/api/download/models/329420; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/checkpoints/animaPencilXL_v310.safetensors https://civitai.com/api/download/models/465206; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then mkdir models/BiRefNet && wget -O models/BiRefNet/BiRefNet-DIS_ep580.pth https://huggingface.co/ViperYX/BiRefNet/resolve/main/BiRefNet-DIS_ep580.pth?download=true; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then wget -O models/BiRefNet/BiRefNet-ep480.pth https://huggingface.co/ViperYX/BiRefNet/resolve/main/BiRefNet-ep480.pth?download=true; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then git clone https://github.com/ZHO-ZHO-ZHO/ComfyUI-BiRefNet-ZHO.git custom_nodes; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then git clone https://github.com/huchenlei/ComfyUI-layerdiffuse.git custom_nodes; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then git clone https://github.com/huchenlei/comfyui-tooling-nodes.git custom_nodes; fi
RUN if [ -z "$SKIP_DEFAULT_MODELS" ]; then git clone https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git custom_nodes; fi

# Install ComfyUI dependencies
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir xformers==0.0.21 \
    && pip3 install -r requirements.txt
RUN pip3 install -r custom_nodes/ComfyUI-layerdiffuse/requirements.txt && pip3 install -r custom_nodes/ComfyUI-BiRefNet-ZHO/requirements.txt


# Install runpod
RUN pip3 install runpod requests

# Support for the network volume
ADD src/extra_model_paths.yaml ./

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
