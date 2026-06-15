// lib/features/bank_accounts/data/bank_account_service.dart

import 'package:cashflowiq/core/network/api_client.dart';
import 'package:cashflowiq/core/utils/data_cache.dart';
import 'package:cashflowiq/shared/models/bank_account.dart';

class BankAccountService {
  // 🏆 GET MOST-USED ACCOUNTS
  Future<List<BankAccount>> getMostUsedAccounts({int limit = 3}) async {
    final List data = await ApiClient.getJson("/bank-accounts/most-used?limit=$limit");
    return data.map((json) => BankAccount.fromJson(json)).toList();
  }

  // 📥 GET ACCOUNTS
  Future<List<BankAccount>> getAccounts() async {
    try {
      const key = 'accounts';
      final cached = DataCache.instance.get<List<BankAccount>>(key);
      if (cached != null) return cached;

      final List data = await ApiClient.getJson("/bank-accounts");
      final accounts = data.map((json) {
        return BankAccount.fromJson(json);
      }).toList();

      DataCache.instance.set(key, accounts);
      return accounts;
    } catch (e) {
      rethrow;
    }
  }

  // ➕ CREATE ACCOUNT
  Future<BankAccount> createAccount(BankAccount account) async {
    final data = await ApiClient.postJson("/bank-accounts", body: account.toJson());
    DataCache.instance.invalidate('accounts');
    return BankAccount.fromJson(data);
  }

  // ✏️ UPDATE ACCOUNT
  Future<BankAccount> updateAccount(BankAccount account) async {
    final data = await ApiClient.putJson("/bank-accounts/${account.id}", body: account.toJson());
    DataCache.instance.invalidate('accounts');
    return BankAccount.fromJson(data);
  }

  // ❌ DELETE ACCOUNT
  Future<void> deleteAccount(String id) async {
    await ApiClient.delete("/bank-accounts/$id");
    DataCache.instance.invalidate('accounts');
  }
}
