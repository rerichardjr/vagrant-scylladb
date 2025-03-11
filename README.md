# Vagrant-ScyllaDB: 3-Node ScyllaDB Cluster

This repository provides a Vagrant configuration to spin up a 3-node ScyllaDB cluster for testing and development purposes. The cluster consists of three virtual machines (`scylladb1`, `scylladb2`, `scylladb3`) running ScyllaDB, configured with private network IPs (`192.168.1.40`, `192.168.1.41`, `192.168.1.42`). Options configurable by changing settings.yaml.

## Prerequisites

- [Vagrant](https://www.vagrantup.com/) installed (see [Installing Vagrant](#installing-vagrant) below).
- [VirtualBox](https://www.virtualbox.org/) (or another supported provider) installed as the virtualization backend.
- Git installed to clone the repository (see [Cloning the Repository](#cloning-the-repository)).

## Getting Started

1. Clone the repository (see [Cloning the Repository](#cloning-the-repository)).
2. Navigate to the repository directory:
   ```bash
   cd vagrant-scylladb
   ```
3. Start the Vagrant environment:
   ```bash
   vagrant up
   ```
   This will provision three VMs, install ScyllaDB, and configure them as a cluster.

4. Wait for the provisioning to complete (this may take a few minutes depending on your system and network).

## Cloning the Repository

To get the code from GitHub:

```bash
git clone https://github.com/rerichardjr/vagrant-scylladb.git
cd vagrant-scylladb
```

- **Requirements**: Git must be installed.
  - On Ubuntu: `sudo apt install git`
  - On macOS: `brew install git` (with Homebrew) or via Xcode tools.
  - On Windows: Download from [git-scm.com](https://git-scm.com/) or use `winget install --id Git.Git`.

## Installing Vagrant

### On Ubuntu/Debian
```bash
sudo apt update
sudo apt install vagrant
```

### On macOS
Using Homebrew:
```bash
brew install vagrant
```
Or download the installer from [vagrantup.com](https://www.vagrantup.com/downloads).

### On Windows
1. Download the installer from [vagrantup.com](https://www.vagrantup.com/downloads).
2. Run the installer and follow the prompts.
3. Alternatively, use Winget:
   ```bash
   winget install Hashicorp.Vagrant
   ```

### Verify Installation
```bash
vagrant --version
```

## Verifying the Cluster with Nodetool

To check the cluster status:

1. SSH into a VM:
   - Use `vagrant ssh` to connect to one of the nodes (e.g., `scylladb1`):
     ```bash
     vagrant ssh scylladb1
     ```
   - This connects you to the `scylladb1` VM.

2. Run Nodetool:
   - Inside the VM, run:
     ```bash
     nodetool status
     ```
   - Output similar to:
     ```bash
     Datacenter: datacenter1
     =======================
     Status=Up/Down
     |/ State=Normal/Leaving/Joining/Moving
     -- Address      Load      Tokens Owns Host ID                              Rack
     UN 192.168.1.40 323.17 KB 1      ?    d04844af-1aac-432f-b45f-dd83cb7fee78 rack1
     UN 192.168.1.41 341.20 KB 1      ?    209ddb0c-dfca-49f9-8e6b-b39c1d6582d9 rack2
     UN 192.168.1.42 380.58 KB 1      ?    bbe8b013-8146-4c43-bac4-2604dfd7e191 rack3
     ```
   - `UN` indicates all nodes are Up and Normal.

3. Exit the VM:
   ```bash
   exit
   ```

## CQLSH Tests

1. SSH into a node:
    ```bash
    vagrant ssh scylladb1
    ```
2. Run `cqlsh`:
    ```bash
    cqlsh
    ```
3. Create a test keyspace:
    ```sql
    CREATE KEYSPACE test_keyspace WITH replication = {'class': 'NetworkTopologyStrategy', 'datacenter1': 3};
    ```
4. Use the `DESCRIBE` command to ensure that `test_keyspace` was created with the correct configuration:
   ```sql
   DESCRIBE KEYSPACE test_keyspace;
   ```
   Check the output to confirm the replication strategy and replication factor are as intended.

5. Within `test_keyspace`, create a test table:
    ```sql
    USE test_keyspace;

    CREATE TABLE test_table (
       id UUID PRIMARY KEY,
       value TEXT
     );
    ```

6. Add some sample data to the table:
    ```sql
    INSERT INTO test_table (id, value) VALUES (uuid(), 'Test Value 1');
    INSERT INTO test_table (id, value) VALUES (uuid(), 'Test Value 2');
    ```

7. Query the data from different nodes in the cluster:
    ```sql
    SELECT * FROM test_table;
    ```
    output:
    ```sql
    id                                   | value
    --------------------------------------+--------------
    99e53c18-49cd-4f2f-aa51-a0e695d67bfb | Test Value 2
    19b6bf29-9bad-4021-bcdd-e373256fb422 | Test Value 1

     (2 rows)
    ```

8. Exit CQLSH
    ```sql
    exit
    ```

9. Use the `nodetool getendpoints` command to confirm which nodes hold replicas for specific partition keys:
    ```bash
    nodetool getendpoints test_keyspace test_table 99e53c18-49cd-4f2f-aa51-a0e695d67bfb
    ```
    output:
    ```bash
    192.168.1.41
    192.168.1.42
    192.168.1.40
    ```

    Note: Replace `<partition_key>` with the ID of an inserted record. Verify that replicas are correctly distributed across nodes as per your keyspace’s replication factor.


## Configuration Details

- **Nodes**: 
  - `scylladb1`: `192.168.1.40`
  - `scylladb2`: `192.168.1.41`
  - `scylladb3`: `192.168.1.42`
- **Vagrant Box**: Uses a base box (e.g., `bento/ubuntu-24.04`) with ScyllaDB installed via provisioning scripts.
- **Network**: Private network with static IPs.
- **ScyllaDB**: Configured with `scylla.yaml` for a 3-node cluster, with scylladb1 as seed.

## Cleaning Up

To stop and remove the VMs:
```bash
vagrant destroy -f
```

## Contributing

Feel free to fork this repo, make improvements, and submit a pull request to `https://github.com/rerichardjr/vagrant-scylladb`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.