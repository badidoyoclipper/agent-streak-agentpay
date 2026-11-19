// Generated from the compiled contract artifacts (forge build). Do not edit by hand.
window.ABIS = {
 "streak": [
  {
   "type": "constructor",
   "inputs": [
    {
     "name": "registry_",
     "type": "address",
     "internalType": "address"
    },
    {
     "name": "gateEnabled_",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "STREAK_BONUS_INTERVAL",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "STREAK_BONUS_POINTS",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "agentIdRegistry",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "address",
     "internalType": "contract IAgentIdRegistry"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "checkIn",
   "inputs": [],
   "outputs": [],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "gateEnabled",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getLongestStreak",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getReputation",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "currentStreak",
     "type": "uint256",
     "internalType": "uint256"
    },
    {
     "name": "longestStreak",
     "type": "uint256",
     "internalType": "uint256"
    },
    {
     "name": "totalCheckIns",
     "type": "uint256",
     "internalType": "uint256"
    },
    {
     "name": "score",
     "type": "uint256",
     "internalType": "uint256"
    },
    {
     "name": "active",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getScore",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getStreak",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getStreakInfo",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "tuple",
     "internalType": "struct AgentStreak.StreakInfo",
     "components": [
      {
       "name": "lastCheckInDay",
       "type": "uint64",
       "internalType": "uint64"
      },
      {
       "name": "currentStreak",
       "type": "uint64",
       "internalType": "uint64"
      },
      {
       "name": "longestStreak",
       "type": "uint64",
       "internalType": "uint64"
      },
      {
       "name": "totalCheckIns",
       "type": "uint64",
       "internalType": "uint64"
      },
      {
       "name": "points",
       "type": "uint64",
       "internalType": "uint64"
      }
     ]
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getTotalCheckIns",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "hasCheckedInToday",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "isActive",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "isAgentIdHolder",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "today",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "totalCheckInsAll",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "totalUsers",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "event",
   "name": "CheckedIn",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "indexed": true,
     "internalType": "address"
    },
    {
     "name": "day",
     "type": "uint256",
     "indexed": false,
     "internalType": "uint256"
    },
    {
     "name": "currentStreak",
     "type": "uint256",
     "indexed": false,
     "internalType": "uint256"
    },
    {
     "name": "points",
     "type": "uint256",
     "indexed": false,
     "internalType": "uint256"
    }
   ],
   "anonymous": false
  },
  {
   "type": "error",
   "name": "AlreadyCheckedInToday",
   "inputs": []
  },
  {
   "type": "error",
   "name": "NotAgentIdHolder",
   "inputs": []
  },
  {
   "type": "error",
   "name": "ZeroAddress",
   "inputs": []
  }
 ],
 "pay": [
  {
   "type": "constructor",
   "inputs": [
    {
     "name": "registry_",
     "type": "address",
     "internalType": "address"
    },
    {
     "name": "gateEnabled_",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "MAX_MEMO_LENGTH",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "agentIdRegistry",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "address",
     "internalType": "contract IAgentIdRegistry"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "cancelRequest",
   "inputs": [
    {
     "name": "id",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "outputs": [],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "createRequest",
   "inputs": [
    {
     "name": "token",
     "type": "address",
     "internalType": "address"
    },
    {
     "name": "amount",
     "type": "uint256",
     "internalType": "uint256"
    },
    {
     "name": "memo",
     "type": "string",
     "internalType": "string"
    }
   ],
   "outputs": [
    {
     "name": "id",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "gateEnabled",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getPayeeRequestIds",
   "inputs": [
    {
     "name": "payee",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256[]",
     "internalType": "uint256[]"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getRequest",
   "inputs": [
    {
     "name": "id",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "tuple",
     "internalType": "struct AgentPay.PaymentRequest",
     "components": [
      {
       "name": "payee",
       "type": "address",
       "internalType": "address"
      },
      {
       "name": "token",
       "type": "address",
       "internalType": "address"
      },
      {
       "name": "amount",
       "type": "uint256",
       "internalType": "uint256"
      },
      {
       "name": "memo",
       "type": "string",
       "internalType": "string"
      },
      {
       "name": "payer",
       "type": "address",
       "internalType": "address"
      },
      {
       "name": "status",
       "type": "uint8",
       "internalType": "enum AgentPay.Status"
      },
      {
       "name": "createdAt",
       "type": "uint64",
       "internalType": "uint64"
      },
      {
       "name": "paidAt",
       "type": "uint64",
       "internalType": "uint64"
      }
     ]
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getStats",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "tuple",
     "internalType": "struct AgentPay.PaymentStats",
     "components": [
      {
       "name": "requestsCreated",
       "type": "uint256",
       "internalType": "uint256"
      },
      {
       "name": "paymentsSent",
       "type": "uint256",
       "internalType": "uint256"
      },
      {
       "name": "paymentsReceived",
       "type": "uint256",
       "internalType": "uint256"
      }
     ]
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getVolumeReceived",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    },
    {
     "name": "token",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "getVolumeSent",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    },
    {
     "name": "token",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "isAgentIdHolder",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "payRequest",
   "inputs": [
    {
     "name": "id",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "outputs": [],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "requestCount",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "totalSettled",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "event",
   "name": "PaymentCancelled",
   "inputs": [
    {
     "name": "id",
     "type": "uint256",
     "indexed": true,
     "internalType": "uint256"
    },
    {
     "name": "payee",
     "type": "address",
     "indexed": true,
     "internalType": "address"
    }
   ],
   "anonymous": false
  },
  {
   "type": "event",
   "name": "PaymentRequested",
   "inputs": [
    {
     "name": "id",
     "type": "uint256",
     "indexed": true,
     "internalType": "uint256"
    },
    {
     "name": "payee",
     "type": "address",
     "indexed": true,
     "internalType": "address"
    },
    {
     "name": "token",
     "type": "address",
     "indexed": true,
     "internalType": "address"
    },
    {
     "name": "amount",
     "type": "uint256",
     "indexed": false,
     "internalType": "uint256"
    },
    {
     "name": "memo",
     "type": "string",
     "indexed": false,
     "internalType": "string"
    }
   ],
   "anonymous": false
  },
  {
   "type": "event",
   "name": "PaymentSettled",
   "inputs": [
    {
     "name": "id",
     "type": "uint256",
     "indexed": true,
     "internalType": "uint256"
    },
    {
     "name": "payer",
     "type": "address",
     "indexed": true,
     "internalType": "address"
    },
    {
     "name": "payee",
     "type": "address",
     "indexed": true,
     "internalType": "address"
    },
    {
     "name": "token",
     "type": "address",
     "indexed": false,
     "internalType": "address"
    },
    {
     "name": "amount",
     "type": "uint256",
     "indexed": false,
     "internalType": "uint256"
    }
   ],
   "anonymous": false
  },
  {
   "type": "error",
   "name": "InvalidAmount",
   "inputs": []
  },
  {
   "type": "error",
   "name": "MemoTooLong",
   "inputs": []
  },
  {
   "type": "error",
   "name": "NotAgentIdHolder",
   "inputs": []
  },
  {
   "type": "error",
   "name": "NotPayee",
   "inputs": []
  },
  {
   "type": "error",
   "name": "RequestNotFound",
   "inputs": []
  },
  {
   "type": "error",
   "name": "RequestNotOpen",
   "inputs": []
  },
  {
   "type": "error",
   "name": "SelfPayment",
   "inputs": []
  },
  {
   "type": "error",
   "name": "TransferFailed",
   "inputs": []
  },
  {
   "type": "error",
   "name": "ZeroAddress",
   "inputs": []
  }
 ],
 "gate": [
  {
   "type": "constructor",
   "inputs": [
    {
     "name": "agentStreak_",
     "type": "address",
     "internalType": "address"
    },
    {
     "name": "threshold_",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "agentStreak",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "address",
     "internalType": "contract IAgentStreak"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "badgeCount",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "canClaim",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "claimBadge",
   "inputs": [],
   "outputs": [],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "hasBadge",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "internalType": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "bool",
     "internalType": "bool"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "owner",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "address",
     "internalType": "address"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "function",
   "name": "setThreshold",
   "inputs": [
    {
     "name": "newThreshold",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "outputs": [],
   "stateMutability": "nonpayable"
  },
  {
   "type": "function",
   "name": "threshold",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint256",
     "internalType": "uint256"
    }
   ],
   "stateMutability": "view"
  },
  {
   "type": "event",
   "name": "BadgeClaimed",
   "inputs": [
    {
     "name": "user",
     "type": "address",
     "indexed": true,
     "internalType": "address"
    },
    {
     "name": "scoreAtClaim",
     "type": "uint256",
     "indexed": false,
     "internalType": "uint256"
    }
   ],
   "anonymous": false
  },
  {
   "type": "event",
   "name": "ThresholdUpdated",
   "inputs": [
    {
     "name": "oldThreshold",
     "type": "uint256",
     "indexed": false,
     "internalType": "uint256"
    },
    {
     "name": "newThreshold",
     "type": "uint256",
     "indexed": false,
     "internalType": "uint256"
    }
   ],
   "anonymous": false
  },
  {
   "type": "error",
   "name": "AlreadyClaimed",
   "inputs": []
  },
  {
   "type": "error",
   "name": "NotOwner",
   "inputs": []
  },
  {
   "type": "error",
   "name": "ScoreTooLow",
   "inputs": [
    {
     "name": "score",
     "type": "uint256",
     "internalType": "uint256"
    },
    {
     "name": "required",
     "type": "uint256",
     "internalType": "uint256"
    }
   ]
  },
  {
   "type": "error",
   "name": "ZeroAddress",
   "inputs": []
  }
 ],
 "registry": [
  {
   "type": "function",
   "name": "balanceOf",
   "stateMutability": "view",
   "inputs": [
    {
     "name": "owner",
     "type": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256"
    }
   ]
  }
 ],
 "erc20": [
  {
   "type": "function",
   "name": "decimals",
   "stateMutability": "view",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "uint8"
    }
   ]
  },
  {
   "type": "function",
   "name": "symbol",
   "stateMutability": "view",
   "inputs": [],
   "outputs": [
    {
     "name": "",
     "type": "string"
    }
   ]
  },
  {
   "type": "function",
   "name": "balanceOf",
   "stateMutability": "view",
   "inputs": [
    {
     "name": "account",
     "type": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256"
    }
   ]
  },
  {
   "type": "function",
   "name": "allowance",
   "stateMutability": "view",
   "inputs": [
    {
     "name": "owner",
     "type": "address"
    },
    {
     "name": "spender",
     "type": "address"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "uint256"
    }
   ]
  },
  {
   "type": "function",
   "name": "approve",
   "stateMutability": "nonpayable",
   "inputs": [
    {
     "name": "spender",
     "type": "address"
    },
    {
     "name": "amount",
     "type": "uint256"
    }
   ],
   "outputs": [
    {
     "name": "",
     "type": "bool"
    }
   ]
  }
 ]
};
