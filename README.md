# Introduction 
In this repository you will find a way to setup your build and release pipeline in Azure DevOps (Azure Pipelines) to use source control for your Azure Data Explorer functions. Any commands for your Azure Data Explorer database within CSL files can be used, although this reference is tested for functions.

## Build

As part of your build pipeline, the script file [pre-deploy.sh](pre-deploy.sh) will run to process the CSL files (located in [/src](/src)) with your Azure Data Explorer commands. The script will capture environment variables from Azure DevOps and create a record of the ingestion
in your database.

The build pipeline can be defined as shown below (see [azure-pipelines.yml](azure-pipelines.yml)). Adjust according to your solution.

```YAML
trigger:
- master

pool:
  vmImage: 'Ubuntu-16.04'

steps:
- task: Bash@3
  displayName: 'Process Files'
  inputs:
    filePath: 'pre-deploy.sh'
  env:
    # Agent variables
    AGENT_BUILD_DIRECTORY: $(Agent.BuildDirectory)
    AGENT_HOME_DIRECTORY: $(Agent.HomeDirectory)
    AGENT_ID: $(Agent.Id)
    AGENT_JOB_NAME: $(Agent.JobName)
    AGENT_JOB_STATUS: $(Agent.JobStatus)
    AGEND_MACHINE_NAME: $(Agent.MachineName)
    AGENT_NAME: $(Agent.Name)
    AGENT_OS: $(Agent.OS)
    AGENT_OS_ARCHITECTURE: $(Agent.OSArchitecture)
    AGENT_TOOLS_DIRECTORY: $(Agent.ToolsDirectory)
    AGENT_WORK_FOLDER: $(Agent.WorkFolder)

    # Build variables
    BUILD_ARTIFACT_STAGING_DIRECTORY: $(Build.ArtifactStagingDirectory)
    BUILD_BUILD_ID: $(Build.BuildId)
    BUILD_BUILD_NUMBER: $(Build.BuildNumber)
    BUILD_BUILD_URI: $(Build.BuildUri)
    BUILD_BINARIES_DIRECTORY: $(Build.BinariesDirectory)
    BUILD_DEFINITION_NAME: $(Build.DefinitionName)
    BUILD_DEFINITION_VERSION: $(Build.DefinitionVersion)
    BUILD_QUEUED_BY: $(Build.QueuedBy)
    BUILD_QUEUED_BY_ID: $(Build.QueuedById)
    BUILD_REASON: $(Build.Reason)
    BUILD_REPOSITORY_CLEAN: $(Build.Repository.Clean)
    BUILD_REPOSITORY_LOCAL_PATH: $(Build.Repository.LocalPath)
    BUILD_REPOSITORY_NAME: $(Build.Repository.Name)
    BUILD_REPOSITORY_PROVIDER: $(Build.Repository.Provider)
    BUILD_REPOSITORY_TFVC_WORKSPACE: $(Build.Repository.Tfvc.Workspace)
    BUILD_REPOSITORY_URI: $(Build.Repository.Uri)
    BUILD_REQUESTED_FOR: $(Build.RequestedFor)
    BUILD_REQUESTED_FOR_EMAIL: $(Build.RequestedForEmail)
    BUILD_REQUESTED_FOR_ID: $(Build.RequestedForId)
    BUILD_SOURCE_BRANCH: $(Build.SourceBranch)
    BUILD_SOURCE_BRANCH_NAME: $(Build.SourceBranchName)
    BUILD_SOURCES_DIRECTORY: $(Build.SourcesDirectory)
    BUILD_SOURCE_VERSION: $(Build.SourceVersion)
    BUILD_SOURCE_VERSION_MESSAGE: $(Build.SourceVersionMessage)
    BUILD_STAGING_DIRECTORY: $(Build.StagingDirectory)
    BUILD_REPOSITORY_GIT_SUBMODULE_CHECKOUT: $(Build.Repository.Git.SubmoduleCheckout)
    BUILD_SOURCE_TFVC_SHELVESET: $(Build.SourceTfvcShelveset)
    BUILD_TRIGGERED_BY_BUILD_ID: $(Build.TriggeredBy.BuildId)
    BUILD_TRIGGERED_BY_DEFINITION_ID: $(Build.TriggeredBy.DefinitionId)
    BUILD_TRIGGERED_BY_DEFINITION_NAME: $(Build.TriggeredBy.DefinitionName)
    BUILD_TRIGGERED_BY_BUILD_NUMBER: $(Build.TriggeredBy.BuildNumber)
    BUILD_TRIGGERED_BY_PROJECT_ID: $(Build.TriggeredBy.ProjectID)
    COMMON_TEST_RESULTS_DIRECTORY: $(Common.TestResultsDirectory)

- task: CopyFiles@2
  displayName: 'Copy Files to: $(Build.ArtifactStagingDirectory)'
  inputs:
    SourceFolder: publish
    Contents: '**'
    TargetFolder: '$(Build.ArtifactStagingDirectory)'

- task: PublishBuildArtifacts@1
  displayName: 'Publish Artifact: drop'
```

## Release

In your release pipeline, a few Azure Data Explorer commands can be included. One is needed to ensure that the table is available in Azure Data Explorer, and one to ingest the CSL files to deploy the functions.

For the table creation, see [Init.csl](Init.csl) for a reference as to how this can be done.

![Release Pipeline](/images/release-pipeline.png "Release Pipeline")

The release pipeline can be defined as shown below. Adjust according to your solution.

```YAML
variables:
  AadClientId: '...'
  AadClientSecret: '...'
  AdxClusterName: '...'
  AdxClusterRegion: '...'
  AdxDatabaseName: '...'

steps:
- task: Azure-Kusto.PublishToADX.PublishToADX.PublishToADX@1
  displayName: Initalize
  inputs:
    script: |
     .create table Deployments (
         BuiltOn:datetime,
         IngestedOn:datetime,
         File:string,
         Checksum:string,
         AgentBuildDirectory:string,
         AgentHomeDirectory:string,
         AgentId:string,
         AgentJobName:string,
         AgentJobStatus:string,
         AgentMachineName:string,
         AgentName:string,
         AgentOS:string,
         AgentOSArchitecture:string,
         AgentToolsDirectory:string,
         AgentWorkFolder:string,
         BuildArtifactStagingDirectory:string,
         BuildBuildId:string,
         BuildBuildNumber:string,
         BuildBuildUri:string,
         BuildBinariesDirectory:string,
         BuildDefinitionName:string,
         BuildDefinitionVersion:string,
         BuildQueuedBy:string,
         BuildQueuedById:string,
         BuildReason:string,
         BuildRepositoryClean:string,
         BuildRepositoryLocalPath:string,
         BuildRepositoryName:string,
         BuildRepositoryProvider:string,
         BuildRepositoryTfvcWorkspace:string,
         BuildRepositoryUri:string,
         BuildRequestedFor:string,
         BuildRequestedForEmail:string,
         BuildRequestedForId:string,
         BuildSourceBranch:string,
         BuildSourceBranchName:string,
         BuildSourcesDirectory:string,
         BuildSourceVersion:string,
         BuildSourceVersionMessage:string,
         BuildStagingDirectory:string,
         BuildRepositoryGitSubmoduleCheckout:string,
         BuildSourceTfvcShelveset:string,
         BuildTriggeredByBuildId:string,
         BuildTriggeredByDefinitionId:string,
         BuildTriggeredByDefinitionName:string,
         BuildTriggeredByBuildNumber:string,
         BuildTriggeredByProjectID:string,
         CommonTestResultsDirectory:string
     )
    kustoUrls: 'https://$(AdxClusterName).$(AdxClusterRegion).kusto.windows.net:443?DatabaseName=$(AdxDatabaseName)'
    aadClientId: '$(AadClientId)'
    aadClientSecret: '$(AadClientSecret)'

- task: Azure-Kusto.PublishToADX.PublishToADX.PublishToADX@1
  displayName: 'Publish Files'
  inputs:
    targetType: ./
    kustoUrls: 'https://$(AdxClusterName).$(AdxClusterRegion).kusto.windows.net:443?DatabaseName=$(AdxDatabaseName)'
    aadClientId: '$(AadClientId)'
    aadClientSecret: '$(AadClientSecret)'
```

# Modify and test
The script file [pre-deploy.sh](pre-deploy.sh) uses environment variables available during the build in Azure Pipelines. However, it can still be modified and executed with the sample folder [/src](/src) in your own environment. It is built to run on Linux-based systems. 

```bash
./pre-deploy.sh
```

After running the script, a new folder named *publish* will be created with the processed CSL files.

# Usage

Once everything is assembled. Records of the ingestion can then be found in the Deployments table in Azure Data Explorer.

```kql
Deployments 
| take 100
```

![Query in Azure Data Explorer](/images/adx.png "Query in Azure Data Explorer")

# Resources
Learn more about Azure Data Explorer and Azure DevOps here:
- [Azure Data Explorer](https://docs.microsoft.com/en-us/azure/data-explorer/)
- [Azure Data Explorer Functions](https://docs.microsoft.com/en-us/azure/kusto/query/functions/)
- [Azure DevOps](https://azure.microsoft.com/en-us/services/devops/)

### Disclaimer ###
**THIS CODE IN THIS REPOSITORY IS PROVIDED *AS IS* WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.**
