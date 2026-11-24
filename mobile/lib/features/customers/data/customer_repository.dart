import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/image_upload.dart';
import 'customer_models.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) => CustomerRepository(ref.watch(dioProvider)));

class CustomerRepository {
  CustomerRepository(this._dio);

  final Dio _dio;

  Future<List<Customer>> list({String search = ''}) => guardApi(() async {
        final res = await _dio.get('/customers', queryParameters: {
          if (search.isNotEmpty) 'search': search,
          'per_page': 100,
        });
        return _list(res.data['data'], Customer.fromJson);
      });

  Future<String> nextCode() => guardApi(() async {
        final res = await _dio.get('/customers/next-code');
        return res.data['customer_code'] as String;
      });

  Future<Customer> get(int id) => guardApi(() async {
        final res = await _dio.get('/customers/$id');
        return Customer.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  Future<Customer> save(Map<String, dynamic> data, {int? id}) => guardApi(() async {
        final res = id == null ? await _dio.post('/customers', data: data) : await _dio.put('/customers/$id', data: data);
        return Customer.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  Future<void> delete(int id) => guardApi(() => _dio.delete('/customers/$id'));

  Future<Customer> updateNotes(int id, {String? healthConditionBefore, String? remarks}) => guardApi(() async {
        final res = await _dio.patch('/customers/$id/notes', data: {
          'health_condition_before': healthConditionBefore,
          'remarks': remarks,
        });
        return Customer.fromJson(res.data['data'] as Map<String, dynamic>);
      });

  Future<List<Measurement>> measurements(int customerId) => guardApi(() async {
        final res = await _dio.get('/customers/$customerId/measurements');
        return _list(res.data['data'], Measurement.fromJson);
      });

  Future<void> saveMeasurement(int customerId, Map<String, dynamic> data, {int? id}) => guardApi(() async {
        if (id == null) {
          await _dio.post('/customers/$customerId/measurements', data: data);
        } else {
          await _dio.put('/customers/$customerId/measurements/$id', data: data);
        }
      });

  Future<void> deleteMeasurement(int customerId, int id) =>
      guardApi(() => _dio.delete('/customers/$customerId/measurements/$id'));

  Future<void> saveProgramme(int customerId, Map<String, dynamic> data, {int? id}) => guardApi(() async {
        if (id == null) {
          await _dio.post('/customers/$customerId/programmes', data: data);
        } else {
          await _dio.put('/customers/$customerId/programmes/$id', data: data);
        }
      });

  Future<void> uploadPhoto(int customerId, String type, XFile file) => guardApi(() async {
        final bytes = await file.readAsBytes();
        final form = FormData.fromMap({
          'type': type,
          'photo': imageMultipart(file, bytes, fallbackName: '$type.jpg'),
        });
        await _dio.post('/customers/$customerId/photos', data: form);
      });

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
