NOTES = %i[C D E F G A B]
SHARPS = %i[Cs Ds Fs Gs As]
FLATS =  %i[Db Eb Gb Ab Bb]
BSPACING = %i[_____ _ _____ _ _]
LSPACING = %i[__|__ _ __|__ _ _]
note_labels = -> (notes, scale_count, octave, filter, space, press, nonpress) {
  labels = notes.cycle(scale_count)
       .each_with_index.map{|n, i| "#{n}#{octave + i / notes.size}" }
       .map{|n| filter.include?(n) ? n : space}
  presslabels = labels.map{|n| filter.include?(n) ? press : nonpress}
  [labels, presslabels]
}
add_spacing = -> (spacing, scale_count, presslabels, charwidth) {
  spacing.cycle(scale_count).map{|x| x}
         .zip(presslabels)
         .flatten
         .join('')[0, charwidth]
}
f= -> (c) {
  ch = c.map{|x| note_info(x).midi_string}.to_a
  has_sharps = ch.any?{|x| x['s']}
  octave = note_info(c[0]).octave
  width = ((c.last - note("C#{octave}"))/ 11.0 * 7).ceil
  key_count = [7, width].max
  scale_count = key_count / 7 + 1

  labels, keypresses   = note_labels[NOTES, scale_count, octave, ch, '  ', ' *', '  ']
  blabels, bkeypresses = note_labels[has_sharps ? SHARPS : FLATS, scale_count, octave, ch, '___', '|*|', '| |']

  charwidth = 1 + key_count*4

  blabels    = add_spacing[BSPACING, scale_count, blabels, charwidth]
  blabels = blabels[2, blabels.size] + '__'

  bkeypresses = add_spacing[LSPACING, scale_count, bkeypresses, charwidth].tr('_',' ')
  bkeypresses = bkeypresses[2, blabels.size] + '| '
  bkeys = bkeypresses.tr('*',' ')

  labels = (' ' + labels.join('  '))[0, charwidth]
  keypresses = ('|' + keypresses.join(' |'))[0, charwidth]
  keys = keypresses.tr(' *','_')

  [
    blabels,
    bkeys,
    bkeys,
    bkeypresses,
    keypresses,
    keys,
    labels
  ].flatten
}

use_synth :dsaw
# with_fx :lpf do
# with_fx :hpf do
chord_names.shuffle.shuffle.take(5).each do |n|
  note = :g3
  c = chord(note, n)
  puts ""
  puts [note, n].join(' ')
  f[c].each {|x| print x} ; nil
  # play c
  # sleep 1
end
# end
# end
