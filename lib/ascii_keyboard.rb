define :ascii_keyboard do |c, tonic=nil|
  return [] if !c || c.size == 0
  NATURALS =  %i[C D E F G A B]
  SHARPS = %i[Cs Ds Fs Gs As]
  FLATS =  %i[Db Eb Gb Ab Bb]
  BSPACING = %i[_____ _ _____ _ _]
  LSPACING = %i[--|-- - --|-- - -]
  SPACE, PRESS, NONPRESS, SPACE2, PRESS2 = '___', '|*|', '|_|', '  ', ' *'
  ch = c.map{|x| note_info(x).midi_string}.to_a
  first_note = note_info(c[0])
  tonic = tonic && note_info(tonic)
  octave = (tonic || first_note).octave
  width = ((c.last - note("C#{octave}"))/ 11.0 * 7).ceil

  truncate_keys = if first_note.interval > 10 && c.size > 3 # above As
               5
             elsif first_note.interval > 8 # above Gs
               4
             elsif first_note.interval > 4 # above F
               3
             else
               0
             end
  key_count = [7, width].max
  key_count = key_count + truncate_keys if key_count < 10
  scale_count = (key_count / 7) + 1
  mod_key_count_zero = key_count % 7 == 0

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

  labels, keypresses   = note_labels[NATURALS, scale_count, octave, ch, SPACE2, PRESS2, SPACE2]
  opts = [scale_count, octave, ch, SPACE, PRESS, NONPRESS]
  slabels, skeypresses = note_labels[SHARPS, *opts]
  flabels, fkeypresses = note_labels[FLATS, *opts]
  blabels     = slabels.zip(flabels).map{|s,f| s == SPACE ? f : s}
  bkeypresses = skeypresses.zip(fkeypresses).map{|s,f| s == NONPRESS ? f : s}

  charwidth = 1 + key_count*4

  blabels = add_spacing[BSPACING, scale_count, blabels, charwidth]
  blabels = blabels[2, blabels.size] + '__'

  bkeypresses = add_spacing[LSPACING, scale_count, bkeypresses, charwidth].tr('-',' ')
  bkeypresses = bkeypresses[2, blabels.size] + (mod_key_count_zero ? ' |' : '| ')
  bkeys = bkeypresses.tr('*_',' ')

  labels = (' ' + labels.join(SPACE2))[0, charwidth]
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
  .map{|line| truncate_keys > 0 ? line[truncate_keys*4, line.size - truncate_keys*4] : line}
end

use_synth :hoover
use_tuning :just
[[:c, :M],[:d, :M],[:e, :m],[:d, :M],[:c, :M]].each do |note, n|
  c = chord(note, n)
  puts ""
  puts [note, n].join(' ')
  ascii_keyboard(c, :c4).each {|x| print x} ; nil
  t = [1,2].sample()
  play c, release: t
  sleep t
end
