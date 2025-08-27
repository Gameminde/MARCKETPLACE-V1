String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Mot de passe requis';
  if (value.length < 8) return 'Minimum 8 caractères';
  if (value.length > 128) return 'Maximum 128 caractères';
  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Au moins 1 majuscule requise';
  if (!RegExp(r'[a-z]').hasMatch(value)) return 'Au moins 1 minuscule requise';
  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Au moins 1 chiffre requis';
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) return 'Au moins 1 caractère spécial requis';
  // Vérifier répétition de caractères
  if (RegExp(r'(.)\1{2,}').hasMatch(value)) return 'Pas de caractères répétitifs';
  const common = ['password', 'password123', '12345678', 'qwerty'];
  // Étendre la liste de mots de passe communs
  const moreCommon = ['abc123','password1','123456789','welcome','admin','letmein'];
  if (moreCommon.contains(value.toLowerCase())) return 'Mot de passe trop commun';
  if (common.contains(value.toLowerCase())) return 'Mot de passe trop commun';
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) return 'Email requis';
  const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  return RegExp(pattern).hasMatch(value) ? null : 'Format email invalide';
}


