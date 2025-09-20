# 🗑️ Complete GCP Resource Deletion Guide

## **Step 0: 🌐 Access Your GCP Project Console**

### **How to Open GCP Console for Your Project:**

1. **Try the direct project URL first:**
   - Go to: **https://console.cloud.google.com/home/dashboard?project=doc-intelligence-1758210325**
   - This should take you directly to your project dashboard

2. **Alternative method - General Console:**
   - Go to: **https://console.cloud.google.com**
   - **Sign in** with your Google account (the one that has access to the project)

3. **Select the correct project:**
   - **IMPORTANT**: GCP Console often defaults to your most recently used project
   - Look at the **top navigation bar** - you'll see the current project name/ID
   - Click on the **project selector dropdown** (it's usually next to the Google Cloud Platform logo)
   - **Search for**: `doc-intelligence-1758210325` in the search box
   - **Select**: `doc-intelligence-1758210325` from the list
   - If you don't see it, try these steps:
     - Click "**ALL**" tab to see all projects
     - Make sure you're signed in with the correct Google account
     - Check if the project was created under a different organization

4. **Verify you're in the right project:**
   - The project name should show: **`doc-intelligence-1758210325`**
   - You should see the project ID in the top navigation bar

5. **If you can't access the project:**
   - Make sure you have the correct permissions
   - You should be either the project owner or have Editor/Admin rights
   - Contact the person who created the project if you don't have access

### **🧭 How to Navigate in GCP Console:**

- **Hamburger Menu (☰):** Click the three horizontal lines in the top-left corner to open the main navigation menu
- **Search Bar:** Use the search bar at the top to quickly find services (e.g., type "Kubernetes" to find GKE)
- **Navigation Menu:** All services are organized in categories like "Compute", "Storage", "Networking", etc.

**Quick Navigation Tips:**
- **Kubernetes Engine** = Compute → Kubernetes Engine
- **SQL** = Storage → SQL  
- **VPC Network** = Networking → VPC Network
- **Secret Manager** = Security → Secret Manager
- **Pub/Sub** = Analytics → Pub/Sub

---

## Step-by-Step Console Deletion Process

### ⚠️ **IMPORTANT: Delete in This Order to Avoid Dependencies**

---

## **1. 🚀 Delete GKE Cluster First (Most Important)**

**Why first?** GKE creates many dependent resources that block other deletions.

1. Go to **Google Cloud Console** → **Kubernetes Engine** → **Clusters**
2. Find cluster: `doc-intel-gke`
3. Click **DELETE**
4. Type the cluster name to confirm
5. **Wait 5-10 minutes** for complete deletion

---

## **2. 🗄️ Delete Databases**

### **Cloud SQL MySQL:**
1. Go to **SQL** → **Instances**
2. Find instance starting with `document-intelligence-mysql-`
3. Click **DELETE**
4. Type `DELETE` to confirm

### **Redis Cache:**
1. Go to **Memorystore** → **Redis**
2. Find instance: `document-intelligence-redis`
3. Click **DELETE**
4. Confirm deletion

---

## **3. 🔐 Delete Secret Manager Secrets**

1. Go to **Security** → **Secret Manager**
2. Delete these secrets:
   - `openai-api-key`
   - `jwt-secret-key`
   - `mysql-password`
3. For each secret: **Actions** → **Delete**

---

## **4. 📦 Delete Container Images**

1. Go to **Artifact Registry** → **Repositories**
2. Find: `document-intelligence-containers`
3. Click **DELETE**
4. Type repository name to confirm

---

## **5. 📨 Delete Pub/Sub Resources**

### **Topics:**
1. Go to **Pub/Sub** → **Topics**
2. Delete these topics:
   - `summarization-jobs`
   - `summarization-jobs-dlq`

### **Subscriptions:**
1. Go to **Pub/Sub** → **Subscriptions**
2. Delete these subscriptions:
   - `summarization-jobs-subscription`
   - `summarization-jobs-dlq-subscription`

---

## **6. 🗂️ Delete Cloud Storage**

1. Go to **Cloud Storage** → **Buckets**
2. Find bucket starting with `document-intelligence-user-images-`
3. **Empty the bucket first** (delete all objects)
4. Then **DELETE** the bucket

---

## **7. 🌐 Delete Networking (LAST)**

**⚠️ Do this LAST after everything else is deleted**

### **Delete Firewall Rules:**
1. Go to **VPC Network** → **Firewall**
2. Delete these rules:
   - `document-intelligence-allow-internal`
   - `document-intelligence-allow-ssh`
   - `document-intelligence-allow-http-https`

### **Delete NAT Gateway:**
1. Go to **Network Services** → **Cloud NAT**
2. Delete: `document-intelligence-nat`

### **Delete Cloud Router:**
1. Go to **Network Connectivity** → **Cloud Routers**
2. Delete: `document-intelligence-router`

### **Delete Subnets:**
1. Go to **VPC Network** → **VPC Networks**
2. Click on `document-intelligence-vpc`
3. Delete subnets:
   - `document-intelligence-private-subnet`
   - `document-intelligence-public-subnet`

### **Delete VPC Network:**

**⚠️ IMPORTANT: If you get "auto-generated peering route cannot be deleted" error:**

1. **First, delete VPC Peering connections:**
   - Go to **VPC Network** → **VPC Network Peering**
   - Look for any peering connections related to `document-intelligence-vpc`
   - Delete any peering connections you find (especially ones related to Cloud SQL or other managed services)

2. **Delete Private Service Connections:**
   - Go to **VPC Network** → **Private Service Connect**
   - Look for any connections related to your VPC
   - Delete them

3. **Alternative: Use gcloud command (if console fails):**
   ```bash
   # List all peering connections
   gcloud compute networks peerings list --network=document-intelligence-vpc
   
   # Delete each peering connection
   gcloud compute networks peerings delete PEERING_NAME --network=document-intelligence-vpc
   ```

4. **Finally, delete the VPC:**
   - Go to **VPC Network** → **VPC Networks**
   - Delete: `document-intelligence-vpc`

---

## **8. 🔑 Delete Service Accounts**

1. Go to **IAM & Admin** → **Service Accounts**
2. Find: `document-intelligence-gke-wi@PROJECT_ID.iam.gserviceaccount.com`
3. Click **DELETE**

---

## **9. 📍 Delete Static IP Addresses**

1. Go to **VPC Network** → **External IP Addresses**
2. Delete any reserved IPs for the project
3. Go to **VPC Network** → **Internal IP Addresses**
4. Delete any reserved internal IPs

---

## **10. 🧹 Clean Up Terraform State**

After deleting everything in the console:

```bash
cd terraform
rm -f terraform.tfstate*
rm -rf .terraform/
```

---

## **✅ Verification Steps**

After deletion, verify nothing is left:

1. **Compute Engine** → **VM Instances** (should be empty)
2. **Kubernetes Engine** → **Clusters** (should be empty)
3. **VPC Network** → **VPC Networks** (only `default` should remain)
4. **Cloud Storage** → **Buckets** (should be empty or only default buckets)
5. **Billing** → **Reports** (check for any ongoing charges)

---

## **🚨 Common Deletion Errors & Solutions:**

### **"Auto-generated peering route cannot be deleted" Error:**
**Cause:** VPC has peering connections to managed services (Cloud SQL, etc.)
**Solution:**
1. Go to **VPC Network** → **VPC Network Peering**
2. Delete all peering connections first
3. Wait 2-3 minutes
4. Try deleting the VPC again

### **"Resource in Use" Errors:**
**Common Dependencies:**
- **GKE Cluster** → Blocks VPC deletion
- **Cloud SQL** → Blocks VPC peering deletion  
- **Load Balancers** → Block firewall rule deletion

**Solution:**
1. Wait 5-10 minutes after deleting each major resource
2. Refresh the console page
3. Try deleting the dependent resource again
4. Check **Operations** in the console for ongoing deletions

### **"Cannot delete subnet" Error:**
**Cause:** Resources still using the subnet
**Solution:**
1. Make sure GKE cluster is completely deleted
2. Check for any remaining VM instances
3. Wait for all operations to complete

---

## **💰 Cost Verification**

After deletion:
1. Go to **Billing** → **Reports**
2. Set date range to "Today"
3. Verify no new charges are accumulating
4. Check **Billing** → **Budgets & Alerts** for any alerts

---

## **🔄 After Complete Deletion**

Once everything is deleted:

```bash
# Clean up local Terraform state
cd terraform
rm -f terraform.tfstate*
rm -rf .terraform/

# Next deployment will create everything fresh
terraform init
terraform plan
terraform apply
```

---

## **⏱️ Expected Time:**
- **GKE Cluster deletion:** 5-10 minutes
- **Database deletion:** 2-5 minutes each
- **Other resources:** 1-2 minutes each
- **Total time:** 15-25 minutes

---

## **🆘 If You Need Help:**

1. Check **Operations** page in GCP Console for ongoing operations
2. Look for error messages in the deletion confirmations
3. Some resources may take time to fully delete - be patient
4. If stuck, wait 10-15 minutes and try again

**Remember: Delete in the order listed above to avoid dependency issues!** 🎯
