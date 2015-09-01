# Tracker

GIT has given developers great flexibility for developer to work offline and anywhere, regardless if there is internet connectivity or not. For issue tracking however, it mostly followed the centralized model, which issue management is connected to a centralized server so that everyone can share the information to be on the same page.

Tracker was rooted on the vision that issue tracking should be at the same flexbility as the version control so that the issue can be kept track as closely to source code changes as possible. If the linkage to the issue tracking to version control is too granular but developer has the option not to register a version control changes to any particular issue in Tracker has all the freedom to do so.

## Pre-requisite

Tracker was last tested on:

* ruby 2.1.4

Tracker is developed using rails 3.2.13 package. It shall be installed when running the bundle install in next step.

## Start the server

Tracker is typical Ruby on Rails application. After cloning to local drive, run the following
```
## Install all dependencies packages
> bundle install
## Create the needed database structure, using environment as been setup by bundle
> bundle exec rake db:migrate
## Start the server
> rails server
## Or with specific port
> rails server -p 3010
```
to start the Tracker.

## Setup

After starting the server, system shall prompt to create the user identity. System also accept any existing PKCS12 keystore and use it as the node user distinct identity.

System shall also generate a unique node ID representing the node identity.

## Distributed Sync

Tracker works as typical issue tracking driven by project created inside the system. All changes created are logged locally and will be replicated to another node upon successfully authenticated. 

Data Sync section available at the left is where data is distributed across multiple nodes. Node can be acted as servicing node or client node.

The operation of the node is similar to git model. 

### Sync Process

Client node is the node which intended to pull records from servicing node.
Servicing node is the ndoe which allow client incoming connection for records synchronization

1. When a node wants to pull record from other node, it has become a client node
2. [Client Node] User go to Data Sync -> Sync Client. From the GUI, the Server Host is the root url of the servicing node. The URL shall need to include the port for example http://10.0.1.1:3010 as Server Host. For initial, client node should be using Pull Operation.
3. [Client Node] For first invocation, the client node shall receive error message indicating failed to login to host and this is normal. This is due to servicing node need to authenticate the client node. All the client information including unique node ID and user ID is sent to servicing node for authentication on the first invocation.
4. [Client Node] Client node now has to wait for the servicing node to authorize the client node.
5. [Servicing Node] User go to Data Sync -> Sync Service. From the Synchronization User list, the user should see there is a user with status 'Pending'. Click on the user ID and servicing node user can verify new user by click on Verified User. Verified user shall changed the status to 'Active'. Once the user ID is active, the client node can now sync with the servicing node. Remote user is said has been authorized to access the servicing node.
6. [Servicing Node] User go to Data Sync -> Nodes and there should be a new node with status 'Pending' in the list. The identifier value is the same as the client node identifier. This client node identifier is located at the footer of the client node GUI. The servicing user can verify this with client node. After verified with client node, servicing node user can click on 'Verified Node' to authorize the client node to access.
7. [Servicing Node] After verify and authorize the client node, servicing node user shall need to click on 'Edit' to define if the particular client node is allow to pull, push and pull or no access. Servicing user can define what this client node user can do from this servicing node.
8. [Client Node] Client node now again go to Data Sync -> Sync Client and enter the same servicing node URL into the Server Host field. Select 'Pull Operation' and click 'Start' and client shall sync all the issues from servicing node to client node. It might take a long time if the client node first time sync with servicing node.

In a nutshell, servicing node is verifying user at two levels, user (via public private keypair) and node unique ID, together with operation that can be performed by the node.

