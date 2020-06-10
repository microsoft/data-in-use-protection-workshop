FROM alpine:3.9 AS installer-env

# Define Args for the needed to add the package
ARG PS_PACKAGE=powershell-7.0.0-linux-alpine-x64.tar.gz
ARG PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v7.0.0/${PS_PACKAGE}
ARG PS_INSTALL_VERSION=7-lts

# Download the Linux tar.gz and save it
ADD ${PS_PACKAGE_URL} /tmp/linux.tar.gz

# define the folder we will be installing PowerShell to
ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/$PS_INSTALL_VERSION

# Create the install folder
RUN mkdir -p ${PS_INSTALL_FOLDER}

# Unzip the Linux tar.gz
RUN tar zxf /tmp/linux.tar.gz -C ${PS_INSTALL_FOLDER} -v

# Start a new stage so we lose all the tar.gz layers from the final image
FROM mcr.microsoft.com/azure-cli:latest

# Copy only the files we need from the previous stage
COPY --from=installer-env ["/opt/microsoft/powershell", "/opt/microsoft/powershell"]

ENV PS_INSTALL_FOLDER=/opt/microsoft/powershell/7-lts \
    \
    # Define ENVs for Localization/Globalization
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    # set a fixed location for the Module analysis cache
    PSModuleAnalysisCachePath=/var/cache/microsoft/powershell/PSModuleAnalysisCache/ModuleAnalysisCache \
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-Alpine-3.9

# Install dotnet dependencies and ca-certificates
RUN apk add --no-cache \
    ca-certificates \
    less \
    \
    # PSReadline/console dependencies
    ncurses-terminfo-base \
    \
    # .NET Core dependencies
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    && apk -X https://dl-cdn.alpinelinux.org/alpine/edge/main add --no-cache \
    lttng-ust \
    \
    # Create the pwsh symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh \
    \
    # Create the pwsh-lts symbolic link that points to powershell
    && ln -s ${PS_INSTALL_FOLDER}/pwsh /usr/bin/pwsh-lts \
    # Give all user execute permissions and remove write permissions for others
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    # intialize powershell module cache
    && pwsh \
    -NoLogo \
    -NoProfile \
    -Command " \
    \$ErrorActionPreference = 'Stop' ; \
    \$ProgressPreference = 'SilentlyContinue' ; \
    while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
    Write-Host "'Waiting for $env:PSModuleAnalysisCachePath'" ; \
    Start-Sleep -Seconds 6 ; \
    }"\
    #Install module for labs such as AzureAD and azcopy
    && pwsh -Command Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force\
    && pwsh -Command Update-Module -Name Az -Force\
    && cd /tmp \
    && curl -L https://aka.ms/downloadazcopy-v10-linux -o az-copy.tar.gz\
    && tar -xvf ./az-copy.tar.gz --strip-components=1\ 
    && cp azcopy /usr/local/bin\
    && rm -rf /tmp/*\
    && apk del curl

COPY . /app
WORKDIR /app
CMD [ "pwsh" ]
