# 🤝 Transparent Aid Distribution

A comprehensive Clarity smart contract for managing transparent aid distribution programs on the Stacks blockchain. This contract enables accountable beneficiary management, donor tracking, and verifiable distribution processes for humanitarian aid organizations.

## 🌟 Features

- **Program Management** 📋: Create and manage aid distribution programs
- **Beneficiary Registry** 👥: Register, verify, and track aid recipients
- **Transparent Donations** 💰: STX-based donation tracking with full transparency
- **Distribution Tracking** 📦: Complete audit trail of all aid distributions
- **Admin Controls** 🔐: Multi-level administrative access control
- **Real-time Statistics** 📊: Program progress and beneficiary analytics
- **Anti-fraud Measures** 🛡️: Blacklisting and verification systems

## 📁 Project Structure

```
transparent-aid-distribution/
├── contracts/
│   └── transparent-aid-distribution.clar    # Main smart contract
├── tests/
│   └── transparent-aid-distribution.test.ts # TypeScript tests
├── Clarinet.toml                            # Project configuration
└── README.md                                # This file
```

## 🛠️ Installation & Setup

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) (for testing)

### Quick Start
```bash
# Clone the repository
git clone <your-repo-url>
cd transparent-aid-distribution

# Check contract syntax
clarinet check

# Run tests
npm install
npm test

# Start local development network
clarinet integrate
```

## 📖 Contract Functions

### Public Functions

#### Program Management
- `create-aid-program` - Create new aid distribution programs
- `suspend-program` - Temporarily suspend programs (owner only)
- `resume-program` - Resume suspended programs (owner only)
- `close-program` - Permanently close programs (admin/owner)

#### Donation Management
- `donate-to-program` - Contribute STX to active programs

#### Beneficiary Management
- `register-beneficiary` - Register aid recipients (admin only)
- `verify-beneficiary` - Verify registered beneficiaries (admin only)
- `blacklist-beneficiary` - Blacklist fraudulent beneficiaries (admin only)

#### Distribution Operations
- `distribute-aid` - Distribute aid to verified beneficiaries (admin only)

#### Administration
- `authorize-admin` - Authorize program administrators (owner only)

### Read-Only Functions
- `get-aid-program` - Retrieve program details
- `get-beneficiary` - Check beneficiary information
- `get-distribution` - View distribution records
- `get-donation` - Check donor contributions
- `get-program-stats` - Program statistics and progress
- `get-administrator` - Admin authorization status
- `get-total-funds` - Total platform donations
- `get-available-funds` - Unallocated funds
- `is-program-expired` - Check program deadline status
- `get-program-progress` - Distribution completion percentage

## 🎯 Usage Examples

### Creating an Aid Program
```clarity
(contract-call? .transparent-aid-distribution create-aid-program
  "Emergency Food Relief"
  "Food assistance for disaster-affected families"
  u100000000  ;; 100 STX total budget
  u1000000    ;; 1 STX per beneficiary
  u1000       ;; Deadline in blocks
  'SP1234567890ABCDEF  ;; Program administrator
)
```

### Donating to a Program
```clarity
(contract-call? .transparent-aid-distribution donate-to-program
  u1         ;; Program ID
  u10000000  ;; 10 STX donation
)
```

### Registering a Beneficiary (Admin Only)
```clarity
(contract-call? .transparent-aid-distribution register-beneficiary
  u1                    ;; Program ID
  'SP-BENEFICIARY-ADDR  ;; Beneficiary address
  "John Doe"            ;; Beneficiary name
)
```

### Verifying a Beneficiary (Admin Only)
```clarity
(contract-call? .transparent-aid-distribution verify-beneficiary
  u1                    ;; Program ID
  'SP-BENEFICIARY-ADDR  ;; Beneficiary address
)
```

### Distributing Aid (Admin Only)
```clarity
(contract-call? .transparent-aid-distribution distribute-aid
  u1                    ;; Program ID
  'SP-BENEFICIARY-ADDR  ;; Beneficiary address
  "Emergency food package distributed"  ;; Distribution notes
)
```

## 📊 Program Status Flow

```
ACTIVE (0) → SUSPENDED (1) → ACTIVE (0)
    ↓             ↓
CLOSED (2) ← CLOSED (2)
```

## 👥 Beneficiary Status Flow

```
REGISTERED (0) → VERIFIED (1) → RECEIVED (2)
      ↓              ↓             ↓
BLACKLISTED (3) ← BLACKLISTED (3) ← BLACKLISTED (3)
```

## 🔒 Security Features

- **Role-based Access Control**: Owner, program admin, and beneficiary permissions
- **Verification Required**: Beneficiaries must be verified before receiving aid
- **Distribution Tracking**: Complete audit trail of all distributions
- **Anti-fraud Protection**: Blacklisting system for fraudulent actors
- **Fund Safety**: STX held in contract escrow until distribution
- **Program Controls**: Suspend/resume functionality for emergency situations

## 📈 Analytics & Reporting

The contract provides comprehensive analytics:
- **Program Statistics**: Total/verified beneficiaries, distributions completed
- **Financial Tracking**: Total donations, distributed amounts, remaining budget
- **Progress Monitoring**: Distribution completion percentages
- **Donor Records**: Individual donation history and totals
- **Distribution History**: Complete record of all aid distributions

## 🧪 Testing

Run the comprehensive test suite:

```bash
npm install
npm test
```

Tests cover:
- Program creation and management
- Donation processing and tracking
- Beneficiary registration and verification
- Aid distribution workflows
- Administrative controls
- Error handling scenarios

## 🚦 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 401 | ERR_UNAUTHORIZED | Access denied |
| 402 | ERR_INVALID_PROGRAM | Invalid program parameters |
| 403 | ERR_BENEFICIARY_NOT_FOUND | Beneficiary doesn't exist |
| 404 | ERR_INSUFFICIENT_FUNDS | Not enough funds available |
| 405 | ERR_ALREADY_DISTRIBUTED | Aid already distributed |
| 406 | ERR_INVALID_AMOUNT | Invalid amount specified |
| 407 | ERR_PROGRAM_CLOSED | Program is closed |
| 408 | ERR_NOT_ELIGIBLE | Beneficiary not eligible |

## 💡 Key Benefits

- **Full Transparency** 🔍: All transactions and distributions are publicly verifiable
- **Reduced Fraud** 🛡️: Multi-step verification and blacklisting capabilities
- **Efficient Distribution** ⚡: Automated aid distribution to verified beneficiaries
- **Donor Confidence** 💪: Complete visibility into fund usage and impact
- **Accountability** 📋: Immutable audit trail of all aid operations
- **Global Access** 🌍: Blockchain-based system accessible worldwide

## 🎯 Use Cases

- **Disaster Relief**: Emergency aid distribution after natural disasters
- **Food Security**: Food assistance programs for vulnerable populations
- **Educational Support**: Scholarships and educational aid distribution
- **Healthcare Aid**: Medical assistance and equipment distribution
- **Community Development**: Local development program funding
- **Refugee Support**: Aid distribution for displaced populations

## 🌟 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add comprehensive tests
5. Run `clarinet check` to validate
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🤝 Support

For questions or support:
- Create an issue on GitHub
- Check the [Stacks documentation](https://docs.stacks.co/)
- Visit the [Clarinet documentation](https://docs.hiro.so/stacks/clarinet-js-sdk)

## 🚀 Deployment

Ready for deployment on:
- **Stacks Testnet**: For testing and development
- **Stacks Mainnet**: For production aid distribution

---

Built with ❤️ for transparent humanitarian aid distribution using Stacks blockchain technology.
