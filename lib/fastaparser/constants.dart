const Map<String, String> nucleotideCodeComplement = {
  'A': 'T',
  'C': 'G',
  'G': 'C',
  'T': 'A',
  'N': 'N',
  'U': 'A',
  'K': 'M',
  'S': 'S',
  'Y': 'R',
  'M': 'K',
  'W': 'W',
  'R': 'Y',
  'B': 'V',
  'D': 'H',
  'H': 'D',
  'V': 'B',
  '-': '-'
};

const Map<String, String> nucleotideNames = {
  'A': 'adenosine',
  'C': 'cytidine',
  'G': 'guanine',
  'T': 'thymidine',
  'N': 'any (A/G/C/T)',
  'U': 'uridine',
  'K': 'keto (G/T)',
  'S': 'strong (G/C)',
  'Y': 'pyrimidine (T/C)',
  'M': 'amino (A/C)',
  'W': 'weak (A/T)',
  'R': 'purine (G/A)',
  'B': 'G/T/C',
  'D': 'G/A/T',
  'H': 'A/C/T',
  'V': 'G/C/A',
  '-': 'gap of indeterminate length'
};

const Map<String, String> aminoacidNames = {
  'A': 'alanine',
  'B': 'aspartate/asparagine',
  'C': 'cystine',
  'D': 'aspartate',
  'E': 'glutamate',
  'F': 'phenylalanine',
  'G': 'glycine',
  'H': 'histidine',
  'I': 'isoleucine',
  'K': 'lysine',
  'L': 'leucine',
  'M': 'methionine',
  'N': 'asparagine',
  'P': 'proline',
  'Q': 'glutamine',
  'R': 'arginine',
  'S': 'serine',
  'T': 'threonine',
  'U': 'selenocysteine',
  'V': 'valine',
  'W': 'tryptophan',
  'Y': 'tyrosine',
  'Z': 'glutamate/glutamine',
  'X': 'any',
  '*': 'translation stop',
  '-': 'gap of indeterminate length'
};

enum SequenceType { nucleotide, aminoacid }

Map<SequenceType, Set<String>> typeToCodesMap = {
  SequenceType.nucleotide: {...nucleotideNames.keys},
  SequenceType.aminoacid: {...aminoacidNames.keys},
};

Set<String> allCodes = typeToCodesMap[SequenceType.aminoacid]!
    .union(typeToCodesMap[SequenceType.nucleotide]!);

Set<String> aminoacidsNotInNucleotides = typeToCodesMap[SequenceType.aminoacid]!
    .difference(typeToCodesMap[SequenceType.nucleotide]!);
