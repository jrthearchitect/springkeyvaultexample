# K8s Springboot App Integration with Azure KeyVault


# This guide will walk you through the end to end process of: 
1. Building a springboot application which pulls secret values from Azure KeyVault 
    (Secrets are made avaialble to the application via environment variables after they are pulled from KeyVault)  -- This happens automagically 
2. Containerizing/Building docker Image of that application
3. Pushing the docker image to your image Repository
4. Deploying the image to a kubernetes cluster with rolling updates enabled.   


# Pre-reqs: 
1.  Azure Subscription with appropriate permissions to create resources
2.  Kubernetes Cluster 
3.  JAVA 
4.  Azure CLI
---------------------------------------------------------------------------------------------------------------------------------------


# Azure Specific Steps: 


# Create Azure Resource Group if you don't already have one for this purpose.   
Replace the name and location variables 
<pre><code>
az group create --name "InsertNameHere" -l "InsertLocationHere"    
</code></pre>

# Create Azure Key Vault  
Replace the name and ResourceGroup name variables
<pre><code>
az keyvault create --name InsertNameHere -g "InsertResourceGroupName"   
</code></pre>

#  replace the variable below with the vault name to be used in next step
<pre><code>
  Example: https://myExampleKeyVaultName.vault.azure.net/  #Please make a note of this URL.   
</code></pre>

# Set your secrets in Vault 
<pre><code>
 az keyvault secret set --vault-name NameofYourKeyVault \
     --name "NameOfSecret" \
     --value "VauleOfSecret"
</code></pre>


# Grant your app access to KeyVault 
<pre><code>
az keyvault set-policy --name tkgi --object-id "InsertObjectIDofServicePrincipal"  --secret-permissions set get list
</code></pre>

---------------------------------------------------------------------------------------------------------------------------------------

# Application Specific Steps: 

-------------------------------------------------
# Optional Step  - Generate a sample project using start.spring.io 
(Only if you're starting from scratch) 
<pre><code>
curl https://start.spring.io/starter.tgz -d dependencies=web,azure-keyvault-secrets -d baseDir=springapp -d bootVersion=2.3.1.RELEASE -d javaVersion=1.8 | tar -xzvf -
</code></pre>
-------------------------------------------------


# Specify your key vault in your app properties 
 Edit —>  src/main/resources/application.properties
 Add the following to the properties file
 <pre><code>
    ###############################################################
                   azure.keyvault.enabled=true
                   azure.keyvault.uri=${vaulturl}
                   azure.keyvault.client-id=${clientid}
                   azure.keyvault.client-key=${clientkey}
                   azure.keyvault.tenant-id=${tenantid}
    ################################################################
</code></pre>


# During Build process of your Code --> 
 Export DEVELOPMENT-ONLY K8s Secrets to environment 
 This will ensure you code builds however it will not save the environment variables with the JAR.   
 When running the JAR, it will require these values to be set via host env or kubenetes secrets depending on your target environment.  
 
 <pre><code>
    ############################################################    
        export clientid=############################
        export clientkey=############################
        export tenantid=############################
        export vaulturl=https://InsertVaultNameHere.vault.azure.net
    ############################################################    
</code></pre>

#Build the code
 <pre><code>
./mvnw clean package 
</code></pre>


#Build docker image from target JAR produced by build
 <pre><code>
docker build -t YourImageRepoLocationNameAndTag .
</code></pre>

#Push docker image to Repository 
 <pre><code>
docker push YourImageRepoLocationNameAndTag:TagName
</code></pre>

---------------------------------------------------------------------------------------------------------------------------------------


# Kubernetes Specific Steps: 


# Create K8s ConfigMap 
 <pre><code>
kubectl apply -f configmap_dev.yaml
</code></pre>

# Create K8s Secret 
 <pre><code>
kubectl create secret generic dev-kv-secret --from-literal=azure_keyvault_client-key=$clientkey
</code></pre>


# Deploy new image to K8s Cluster 
 <pre><code>
kubectl apply -f deployment.yaml
</code></pre>


# Initiate Rolling Update 
 <pre><code>
kubectl rollout restart -f deployment.yaml
</code></pre>
