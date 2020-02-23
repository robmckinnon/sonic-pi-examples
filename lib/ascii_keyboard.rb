def s k, v
  set k, v unless get[k]
end

s :naturals, %i[C D E F G A B]
s :sharps, %i[Cs Ds Fs Gs As]
s :flats, %i[Db Eb Gb Ab Bb]
s :b_space, %i[_____ _ _____ _ _]
s :l_space, %i[--|-- - --|-- - -]
s :space_1, '___'
s :press_1, '|*|'
s :nopress, '|_|'
s :space_2, '  '
s :press_2, ' *'

def truncate_keys(interval, count)
   if interval > 10 && count > 3 # above As
     5
   elsif interval > 8 # above Gs
     4
   elsif interval > 4 # above F
     3
   else
     0
   end
end

def note_labels(notes, scale_count, octave, filter, space, press, nonpress)
  labels = get[notes].cycle(scale_count)
    .each_with_index.map{|n, i| "#{n}#{octave + i / get[notes].size}" }
    .map{|n| filter.include?(n) ? n : get[space]}
  presslabels = labels.map{|n| filter.include?(n) ? get[press] : get[nonpress]}
  [labels, presslabels]
end
def add_spacing(spacing, scale_count, presslabels, charwidth)
  get[spacing].cycle(scale_count).map{|x| x}
    .zip(presslabels)
    .flatten
    .join('')[0, charwidth]
end

@ak_cache = {}

define :ascii_keyboard do |c, tonic=nil|
  return [] if !c || c.size == 0
  key = [c.to_a, tonic]
  return @ak_cache[key] if @ak_cache[key]

  tonic = note_info(tonic) unless tonic.nil?
  first_note = note_info(c[0])
  octave = (tonic || first_note).octave
  width = ((c.last - note("C#{octave}"))/ 11.0 * 7).ceil

  truncate_keys = truncate_keys(first_note.interval, c.size)
  key_count = [7, width].max
  key_count = key_count + truncate_keys if key_count < 10
  scale_count = (key_count / 7) + 1
  ch = c.map{|x| note_info(x).midi_string}.to_a

  opts = [scale_count, octave, ch, :space_2, :press_2, :space_2]
  labels, keypresses   = note_labels :naturals, *opts

  opts = [scale_count, octave, ch, :space_1, :press_1, :nopress]
  slabels, skeypresses = note_labels :sharps, *opts
  flabels, fkeypresses = note_labels :flats, *opts

  blabels     = slabels.zip(flabels).map{|s,f| s == get[:space_1] ? f : s}
  bkeypresses = skeypresses.zip(fkeypresses).map{|s,f| s == get[:nopress] ? f : s}

  charwidth = 1 + key_count*4

  blabels = add_spacing :b_space, scale_count, blabels, charwidth
  blabels = blabels[2, blabels.size] + '__'

  bkeypresses = add_spacing(:l_space, scale_count, bkeypresses, charwidth).tr('-',' ')
  mod_key_count_zero = key_count % 7 == 0
  bkeypresses = bkeypresses[2, blabels.size] + (mod_key_count_zero ? ' |' : '| ')
  bkeys = bkeypresses.tr('*_',' ')

  labels = (' ' + labels.join(get[:space_2]))[0, charwidth]
  keypresses = ('|' + keypresses.join(' |'))[0, charwidth]
  keys = keypresses.tr(' *','_')

  lines = [
    blabels,
    bkeys,
    bkeys,
    bkeypresses,
    keypresses,
    keys,
    labels
  ].flatten
  .map{|line| truncate_keys > 0 ? line[truncate_keys*4, line.size - truncate_keys*4] : line}
  @ak_cache[key] = lines
  lines
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
