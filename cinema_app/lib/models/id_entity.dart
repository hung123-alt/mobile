
class IdEntity<T extends num> {
  final T id;

  IdEntity({required this.id});

  T getId() => id;
  T setId(T newId) => newId;

  @override
  String toString() => 'IdEntity{id: $id}';
}
