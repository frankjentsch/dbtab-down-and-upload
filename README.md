# Download and Upload of Table Data for SAP Cloud Platform ABAP Environment
This Git repository provides an utility to download and upload table data from one <em>SAP Cloud Platform ABAP Environment</em> system to another.

## Prerequisites
Make sure to fulfill the following requirements:
* You have access to an SAP Cloud Platform ABAP Environment instance (see [here](https://blogs.sap.com/2018/09/04/sap-cloud-platform-abap-environment) for additional information).
* You have downloaded and installed ABAP Development Tools (ADT). Make sure to use the most recent version as indicated on the [installation page](https://tools.hana.ondemand.com/#abap). 
* You have created an ABAP Cloud Project in ADT that allows you to access your SAP Cloud Platform ABAP Environment instance (see [here](https://help.sap.com/viewer/5371047f1273405bb46725a417f95433/Cloud/en-US/99cc54393e4c4e77a5b7f05567d4d14c.html) for additional information). Your log-on language is English.
* You have installed the [abapGit](https://github.com/abapGit/eclipse.abapgit.org) plug-in for ADT from the update site `http://eclipse.abapgit.org/updatesite/`.

## Download
Use the abapGit plug-in to install the **Download and Upload of Table Data** by executing the following steps:
1. Optional, but recommended if two different systems are involved: Open the Administrator's Fiori Launchpad and start the app **Maintain Software Components**. Create a new software component `ZDBTAB_DATA` of type *Development*. Press the button *Pull* to create the software component and the stucture package with the same name `ZDBTAB_DATA` in the ABAP system.
2. In your ABAP cloud project, create the ABAP package `ZDBTAB_DOWN_AND_UPLOAD` (using the superpackage `ZDBTAB_DATA`) as the target package for the utility to be downloaded (leave the suggested values unchanged when following the steps in the package creation wizard).
3. To add the <em>abapGit Repositories</em> view to the <em>ABAP</em> perspective, click `Window` > `Show View` > `Other...` from the menu bar and choose `abapGit Repositories`.
4. In the <em>abapGit Repositories</em> view, click the `+` icon to clone an abapGit repository.
5. Enter the following URL of this repository: `https://github.com/frankjentsch/dbtab-down-and-upload.git` and choose <em>Next</em>.
6. Select the branch <em>refs/heads/main</em> and enter the newly created package `ZDBTAB_DOWN_AND_UPLOAD` as the target package and choose <em>Next</em>.
7. Create a new transport request that you only use for this utility installation (recommendation) and choose <em>Finish</em> to link the Git repository to your ABAP cloud project. The repository appears in the abapGit Repositories View with status <em>Linked</em>.
8. Right-click on the new ABAP repository and choose `pull` to start the cloning of the repository contents. Note that this procedure may take a few seconds. 
9. Once the cloning has finished, the status is set to `Pulled Successfully`. (Refresh the `abapGit Repositories` view to see the progress of the import). Then refresh your project tree. 

As a result of the installation procedure above, the ABAP system creates an inactive version of all artifacts for the utility. Unfortuntely, further manual steps are required to finally use the utility. Please refer to the next section.

## Configuration

To activate all development objects from the `ZDBTAB_DOWN_AND_UPLOAD` package: 
1. Click the mass-activation icon (<em>Activate Inactive ABAP Development Objects</em>) in the toolbar.  
2. In the dialog that appears, select all development objects in the transport request (that you created for the untility installation) and choose `Activate`. 

To create the required *HTTP Service* objects:
1. In each service binding, choose the button `Publish` or choose `Publish local service endpoint` in the top right corner of the editor.

To fill the demo database tables for develop scenarios with sample business data: 
1. Expand the package structure in the Project Explorer `/DMO/FLIGHT_LEGACY` > `Source Code Library` > `Classes`.
2. Select the data generator class `/DMO/CL_FLIGHT_DATA_GENERATOR` and press `F9` (Run as Console Application). 

## How to obtain support
This project is provided "as-is": there is no guarantee that raised issues will be answered or addressed in future releases.