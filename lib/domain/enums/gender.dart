enum Gender {
  male('Masculino'),
  female('Feminino'),
  other('Outro');

  const Gender(this.displayName);

  final String displayName;
}
