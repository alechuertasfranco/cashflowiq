// lib/features/bank_accounts/data/bank_account_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';
import 'package:flutter/widgets.dart';

class BankAccountService {
  // 📥 GET ACCOUNTS
  Future<List<BankAccount>> getAccounts() async {
    try {
      final List data = await ApiClient.getJson("/bank-accounts");
      debugPrint("Fetched accounts: $data");
      final accounts = data.map((json) {
        return BankAccount.fromJson(json);
      }).toList();

      return accounts;
    } catch (e) {
      rethrow;
    }
  }

  // ➕ CREATE ACCOUNT
  Future<BankAccount> createAccount(BankAccount account) async {
    final data = await ApiClient.postJson("/bank-accounts", body: account.toJson());
    return BankAccount.fromJson(data);
  }

  // ✏️ UPDATE ACCOUNT
  Future<BankAccount> updateAccount(BankAccount account) async {
    final data = await ApiClient.putJson("/bank-accounts/${account.id}", body: account.toJson());
    return BankAccount.fromJson(data);
  }

  // ❌ DELETE ACCOUNT
  Future<void> deleteAccount(String id) async {
    await ApiClient.delete("/bank-accounts/$id");
  }
}
