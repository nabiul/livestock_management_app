import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';
import 'generic/resource_screen.dart';
import 'livestock_detail_screen.dart';

Widget farmsModule(ApiClient api) => ResourceScreen(
  api: api,
  title: 'Farms',
  endpoint: 'farms',
  permission: 'farms',
  icon: Icons.home_work_outlined,
  itemTitle: (item) => '${item['name']}',
  itemSubtitle: (item) =>
      '${item['farm_type'] ?? 'mixed'} · ${item['district'] ?? 'District not set'} · ${item['animals_count'] ?? 0} livestock',
  fields: const [
    FieldSpec('name', 'Farm name', required: true),
    FieldSpec(
      'farm_type',
      'Farm type',
      type: FieldType.select,
      options: ['cattle', 'dairy', 'goat', 'sheep', 'poultry', 'mixed'],
      defaultValue: 'mixed',
      required: true,
    ),
    FieldSpec('district', 'District'),
  ],
);

Widget animalsModule(ApiClient api) => ResourceScreen(
  api: api,
  title: 'Livestock',
  endpoint: 'animals',
  permission: 'livestock',
  icon: Icons.pets_outlined,
  detailBuilder: (item) => LivestockDetailScreen(
    api: api,
    recordId: item['id'] as int,
    isBatch: false,
  ),
  itemTitle: (item) => '${item['tag_number']} ${item['name'] ?? ''}',
  itemSubtitle: (item) =>
      '${item['species']?['name'] ?? 'Species'} · ${item['breed'] ?? 'No breed'} · ${item['farm']?['name'] ?? ''} · ${item['status'] ?? 'active'}',
  fields: const [
    FieldSpec(
      'farm_id',
      'Farm',
      type: FieldType.lookup,
      lookupPath: 'farms',
      required: true,
    ),
    FieldSpec(
      'species_id',
      'Species',
      type: FieldType.lookup,
      lookupPath: 'species',
      required: true,
    ),
    FieldSpec('tag_number', 'Tag number', required: true),
    FieldSpec('name', 'Animal name'),
    FieldSpec(
      'sex',
      'Sex',
      type: FieldType.select,
      options: ['male', 'female'],
    ),
    FieldSpec('breed', 'Breed'),
    FieldSpec('date_of_birth', 'Date of birth', type: FieldType.date),
    FieldSpec(
      'status',
      'Status',
      type: FieldType.select,
      options: ['active', 'sold', 'deceased', 'transferred'],
      defaultValue: 'active',
      required: true,
    ),
  ],
);

Widget inventoryModule(ApiClient api) => ResourceScreen(
  api: api,
  title: 'Inventory',
  endpoint: 'inventory-items',
  permission: 'inventory',
  icon: Icons.inventory_2_outlined,
  itemTitle: (item) => '${item['name']}',
  itemSubtitle: (item) =>
      '${item['category']} · ${item['quantity']} ${item['unit']} · Avg ${moneyFormat.format(num.tryParse('${item['average_unit_cost']}') ?? 0)}',
  fields: const [
    FieldSpec(
      'farm_id',
      'Farm',
      type: FieldType.lookup,
      lookupPath: 'farms',
      required: true,
    ),
    FieldSpec('name', 'Item name', required: true),
    FieldSpec(
      'category',
      'Category',
      type: FieldType.select,
      options: [
        'feed',
        'production',
        'medicine',
        'vaccine',
        'equipment',
        'supplies',
        'other',
      ],
      required: true,
    ),
    FieldSpec(
      'unit',
      'Unit',
      type: FieldType.select,
      options: ['kg', 'gram', 'litre', 'ml', 'piece', 'dozen', 'bag', 'box'],
      required: true,
    ),
    FieldSpec(
      'quantity',
      'Opening quantity',
      type: FieldType.number,
      defaultValue: 0,
      createOnly: true,
    ),
    FieldSpec(
      'reorder_level',
      'Reorder level',
      type: FieldType.number,
      defaultValue: 0,
      required: true,
    ),
    FieldSpec(
      'average_unit_cost',
      'Average unit cost',
      type: FieldType.number,
      defaultValue: 0,
      required: true,
    ),
    FieldSpec('supplier_name', 'Supplier'),
  ],
);

Widget contactsModule(ApiClient api) => ResourceScreen(
  api: api,
  title: 'Parties',
  endpoint: 'contacts',
  permission: 'contacts',
  icon: Icons.people_alt_outlined,
  itemTitle: (item) => '${item['name']}',
  itemSubtitle: (item) {
    final balance =
        (num.tryParse('${item['debit_total']}') ?? 0) -
        (num.tryParse('${item['credit_total']}') ?? 0);
    return '${item['type']} · ${item['phone'] ?? 'No phone'} · Balance ${moneyFormat.format(balance)}';
  },
  fields: const [
    FieldSpec(
      'type',
      'Party type',
      type: FieldType.select,
      options: ['customer', 'vendor', 'both'],
      required: true,
    ),
    FieldSpec('name', 'Name', required: true),
    FieldSpec('phone', 'Phone'),
    FieldSpec('email', 'Email'),
    FieldSpec('address', 'Address', type: FieldType.multiline),
  ],
);

Widget accountsModule(ApiClient api) => ResourceScreen(
  api: api,
  title: 'Cash & bank',
  endpoint: 'accounts',
  permission: 'accounts',
  icon: Icons.account_balance_wallet_outlined,
  itemTitle: (item) => '${item['name']}',
  itemSubtitle: (item) =>
      '${item['type']} · ${item['account_number'] ?? ''} · ${moneyFormat.format(num.tryParse('${item['current_balance']}') ?? 0)}',
  fields: const [
    FieldSpec('name', 'Account name', required: true),
    FieldSpec(
      'type',
      'Account type',
      type: FieldType.select,
      options: ['cash', 'bank', 'mobile'],
      required: true,
    ),
    FieldSpec('account_number', 'Account number'),
    FieldSpec(
      'opening_balance',
      'Opening balance',
      type: FieldType.number,
      defaultValue: 0,
      createOnly: true,
      required: true,
    ),
    FieldSpec(
      'is_active',
      'Active',
      type: FieldType.toggle,
      defaultValue: true,
    ),
  ],
);

Widget productionModule(ApiClient api) => ResourceScreen(
  api: api,
  title: 'Production',
  endpoint: 'production-records',
  permission: 'production',
  icon: Icons.egg_alt_outlined,
  itemTitle: (item) => '${item['type']}'.toUpperCase(),
  itemSubtitle: (item) {
    dynamic source = item['farm']?['name'];
    if (item['source_type'] == 'individual') {
      source = item['animal']?['tag_number'];
    } else if (item['source_type'] == 'batch') {
      source = item['source_livestock_batch']?['batch_code'];
    }
    return '${item['quantity']} ${item['unit']} · ${formatAppDate(item['recorded_on'])} · ${item['source_type'] ?? 'farm'}: ${source ?? 'Unknown'}';
  },
  fields: const [
    FieldSpec(
      'farm_id',
      'Farm',
      type: FieldType.lookup,
      lookupPath: 'farms',
      required: true,
    ),
    FieldSpec(
      'source_type',
      'Production source',
      type: FieldType.select,
      options: ['individual', 'batch', 'farm'],
      defaultValue: 'individual',
      required: true,
    ),
    FieldSpec(
      'animal_id',
      'Individual livestock',
      type: FieldType.lookup,
      lookupPath: 'animals',
      lookupLabel: _animalLabel,
      availableOnly: true,
      required: true,
      visibleWhenKey: 'source_type',
      visibleWhenValues: ['individual'],
    ),
    FieldSpec(
      'source_livestock_batch_id',
      'Producing batch',
      type: FieldType.lookup,
      lookupPath: 'livestock-batches',
      lookupLabel: _batchLabel,
      required: true,
      visibleWhenKey: 'source_type',
      visibleWhenValues: ['batch'],
    ),
    FieldSpec(
      'inventory_item_id',
      'Add product to inventory',
      type: FieldType.lookup,
      lookupPath: 'inventory-items',
      hiddenWhenKey: 'type',
      hiddenWhenValues: ['birth', 'hatch'],
    ),
    FieldSpec(
      'newborn_destination',
      'Newborn registration',
      type: FieldType.select,
      options: ['batch', 'individual'],
      defaultValue: 'batch',
      required: true,
      visibleWhenKey: 'type',
      visibleWhenValues: ['birth', 'hatch'],
    ),
    FieldSpec(
      'livestock_batch_id',
      'Newborn destination batch',
      type: FieldType.lookup,
      lookupPath: 'livestock-batches',
      lookupLabel: _batchLabel,
      required: true,
      visibleWhenKey: 'newborn_destination',
      visibleWhenValues: ['batch'],
      hiddenWhenKey: 'type',
      hiddenWhenValues: [
        'milk',
        'egg',
        'wool',
        'weight',
        'meat',
        'manure',
        'other',
      ],
    ),
    FieldSpec(
      'offspring_species_id',
      'Newborn species',
      type: FieldType.lookup,
      lookupPath: 'species',
      required: true,
      visibleWhenKey: 'newborn_destination',
      visibleWhenValues: ['individual'],
      hiddenWhenKey: 'type',
      hiddenWhenValues: [
        'milk',
        'egg',
        'wool',
        'weight',
        'meat',
        'manure',
        'other',
      ],
    ),
    FieldSpec(
      'offspring_tag_number',
      'Newborn tag number',
      required: true,
      visibleWhenKey: 'newborn_destination',
      visibleWhenValues: ['individual'],
      hiddenWhenKey: 'type',
      hiddenWhenValues: [
        'milk',
        'egg',
        'wool',
        'weight',
        'meat',
        'manure',
        'other',
      ],
    ),
    FieldSpec(
      'offspring_name',
      'Newborn name',
      visibleWhenKey: 'newborn_destination',
      visibleWhenValues: ['individual'],
      hiddenWhenKey: 'type',
      hiddenWhenValues: [
        'milk',
        'egg',
        'wool',
        'weight',
        'meat',
        'manure',
        'other',
      ],
    ),
    FieldSpec(
      'offspring_sex',
      'Newborn sex',
      type: FieldType.select,
      options: ['male', 'female'],
      visibleWhenKey: 'newborn_destination',
      visibleWhenValues: ['individual'],
      hiddenWhenKey: 'type',
      hiddenWhenValues: [
        'milk',
        'egg',
        'wool',
        'weight',
        'meat',
        'manure',
        'other',
      ],
    ),
    FieldSpec(
      'offspring_breed',
      'Newborn breed',
      visibleWhenKey: 'newborn_destination',
      visibleWhenValues: ['individual'],
      hiddenWhenKey: 'type',
      hiddenWhenValues: [
        'milk',
        'egg',
        'wool',
        'weight',
        'meat',
        'manure',
        'other',
      ],
    ),
    FieldSpec(
      'type',
      'Production type',
      type: FieldType.select,
      options: [
        'milk',
        'egg',
        'wool',
        'weight',
        'meat',
        'manure',
        'birth',
        'hatch',
        'other',
      ],
      required: true,
    ),
    FieldSpec('quantity', 'Quantity', type: FieldType.number, required: true),
    FieldSpec(
      'unit',
      'Unit',
      type: FieldType.select,
      options: ['litre', 'kg', 'gram', 'piece', 'dozen', 'head'],
      required: true,
    ),
    FieldSpec('recorded_on', 'Date', type: FieldType.date, required: true),
    FieldSpec('quality_grade', 'Quality grade'),
    FieldSpec('unit_price', 'Expected unit price', type: FieldType.number),
    FieldSpec('notes', 'Notes', type: FieldType.multiline),
  ],
);

Widget accountingModule(ApiClient api) => ResourceScreen(
  api: api,
  title: 'Accounting',
  endpoint: 'financial-transactions',
  permission: 'accounting',
  icon: Icons.receipt_long_outlined,
  itemTitle: (item) => '${item['type']}'.toUpperCase(),
  itemSubtitle: (item) =>
      '${moneyFormat.format(num.tryParse('${item['amount']}') ?? 0)} · ${formatAppDate(item['transaction_date'])} · ${item['animal']?['tag_number'] ?? item['livestock_batch']?['batch_code'] ?? item['reference'] ?? 'Business'}',
  fields: const [
    FieldSpec('farm_id', 'Farm', type: FieldType.lookup, lookupPath: 'farms'),
    FieldSpec(
      'animal_id',
      'Individual livestock (optional)',
      type: FieldType.lookup,
      lookupPath: 'animals',
      lookupLabel: _animalLabel,
      availableOnly: true,
    ),
    FieldSpec(
      'livestock_batch_id',
      'Livestock batch (optional)',
      type: FieldType.lookup,
      lookupPath: 'livestock-batches',
      lookupLabel: _batchLabel,
    ),
    FieldSpec(
      'type',
      'Type',
      type: FieldType.select,
      options: ['income', 'expense'],
      required: true,
    ),
    FieldSpec(
      'financial_category_id',
      'Category',
      type: FieldType.lookup,
      lookupPath: 'financial-categories',
      required: true,
    ),
    FieldSpec(
      'financial_account_id',
      'Cash / bank account',
      type: FieldType.lookup,
      lookupPath: 'accounts',
      required: true,
    ),
    FieldSpec('amount', 'Amount', type: FieldType.number, required: true),
    FieldSpec(
      'vat_amount',
      'VAT amount',
      type: FieldType.number,
      defaultValue: 0,
    ),
    FieldSpec(
      'tax_amount',
      'Tax amount',
      type: FieldType.number,
      defaultValue: 0,
    ),
    FieldSpec('transaction_date', 'Date', type: FieldType.date, required: true),
    FieldSpec('reference', 'Reference'),
    FieldSpec('notes', 'Notes', type: FieldType.multiline),
  ],
);

Widget categoriesModule(ApiClient api) => ResourceScreen(
  api: api,
  title: 'Accounting categories',
  endpoint: 'financial-categories',
  permission: 'accounting',
  icon: Icons.category_outlined,
  itemTitle: (item) => '${item['name']}',
  itemSubtitle: (item) => '${item['type']}'.toUpperCase(),
  fields: const [
    FieldSpec('name', 'Category name', required: true),
    FieldSpec(
      'type',
      'Category type',
      type: FieldType.select,
      options: ['income', 'expense'],
      required: true,
    ),
    FieldSpec(
      'is_active',
      'Active',
      type: FieldType.toggle,
      defaultValue: true,
    ),
  ],
);

String _animalLabel(Map<String, dynamic> item) =>
    '${item['tag_number']} ${item['name'] ?? ''}';
String _batchLabel(Map<String, dynamic> item) =>
    '${item['batch_code']} · ${item['current_quantity']} head';
