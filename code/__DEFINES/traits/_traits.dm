#define SIGNAL_ADDTRAIT(trait_ref) ("addtrait " + trait_ref)
#define SIGNAL_REMOVETRAIT(trait_ref) ("removetrait " + trait_ref)

// trait accessor defines
#define ADD_TRAIT(target, trait, source) \
	do { \
		var/list/_L; \
		if (!target._status_traits) { \
			target._status_traits = list(); \
			_L = target._status_traits; \
			_L[trait] = list(source); \
			SEND_SIGNAL(target, SIGNAL_ADDTRAIT(trait), trait); \
		} else { \
			_L = target._status_traits; \
			if (_L[trait]) { \
				_L[trait] |= list(source); \
			} else { \
				_L[trait] = list(source); \
				SEND_SIGNAL(target, SIGNAL_ADDTRAIT(trait), trait); \
			} \
		} \
	} while (0)
#define REMOVE_TRAIT(target, trait, sources) \
	do { \
		var/list/_L = target._status_traits; \
		var/list/_S; \
		if (sources && !islist(sources)) { \
			_S = list(sources); \
		} else { \
			_S = sources\
		}; \
		if (_L?[trait]) { \
			for (var/_T in _L[trait]) { \
				if ((!_S && (_T != ROUNDSTART_TRAIT)) || (_T in _S)) { \
					_L[trait] -= _T \
				} \
			};\
			if (!length(_L[trait])) { \
				_L -= trait; \
				SEND_SIGNAL(target, SIGNAL_REMOVETRAIT(trait), trait); \
			}; \
			if (!length(_L)) { \
				target._status_traits = null \
			}; \
		} \
	} while (0)
#define REMOVE_TRAIT_NOT_FROM(target, trait, sources) \
	do { \
		var/list/_traits_list = target._status_traits; \
		var/list/_sources_list; \
		if (sources && !islist(sources)) { \
			_sources_list = list(sources); \
		} else { \
			_sources_list = sources\
		}; \
		if (_traits_list?[trait]) { \
			for (var/_trait_source in _traits_list[trait]) { \
				if (!(_trait_source in _sources_list)) { \
					_traits_list[trait] -= _trait_source \
				} \
			};\
			if (!length(_traits_list[trait])) { \
				_traits_list -= trait; \
				SEND_SIGNAL(target, SIGNAL_REMOVETRAIT(trait), trait); \
			}; \
			if (!length(_traits_list)) { \
				target._status_traits = null \
			}; \
		} \
	} while (0)
#define REMOVE_TRAITS_NOT_IN(target, sources) \
	do { \
		var/list/_L = target._status_traits; \
		var/list/_S = sources; \
		if (_L) { \
			for (var/_T in _L) { \
				if (_L[_T]) { \
					_L[_T] &= _S; \
				}; \
				if (!length(_L[_T])) { \
					_L -= _T; \
					SEND_SIGNAL(target, SIGNAL_REMOVETRAIT(_T), _T); \
					}; \
				};\
			if (!length(_L)) { \
				target._status_traits = null\
			};\
		}\
	} while (0)

#define REMOVE_TRAITS_IN(target, sources) \
	do { \
		var/list/_L = target._status_traits; \
		var/list/_S = sources; \
		if (sources && !islist(sources)) { \
			_S = list(sources); \
		} else { \
			_S = sources\
		}; \
		if (_L) { \
			for (var/_T in _L) { \
				if (_L[_T]) { \
					_L[_T] -= _S; \
				}; \
				if (!length(_L[_T])) { \
					_L -= _T; \
					SEND_SIGNAL(target, SIGNAL_REMOVETRAIT(_T), _T); \
					}; \
				};\
			if (!length(_L)) { \
				target._status_traits = null\
			};\
		}\
	} while (0)

#define HAS_TRAIT(target, trait) (target?._status_traits?[trait] ? TRUE : FALSE)
#define HAS_TRAIT_FROM(target, trait, source) (HAS_TRAIT(target, trait) && (source in target._status_traits[trait]))
#define HAS_TRAIT_FROM_ONLY(target, trait, source) (HAS_TRAIT(target, trait) && (source in target._status_traits[trait]) && (length(target._status_traits[trait]) == 1))
#define HAS_TRAIT_NOT_FROM(target, trait, source) (HAS_TRAIT(target, trait) && (length(target._status_traits[trait] - source) > 0))
/// Returns a list of trait sources for this trait. Only useful for wacko cases and internal futzing
/// You should not be using this
#define GET_TRAIT_SOURCES(target, trait) (target?._status_traits?[trait] || list())
/// Returns the amount of sources for a trait. useful if you don't want to have a "thing counter" stuck around all the time
#define COUNT_TRAIT_SOURCES(target, trait) length(GET_TRAIT_SOURCES(target, trait))

// Mind trait helpers - rule of thumb is they work with the mind's mob if it exists, otherwise they fall back to the target itself.
/// Checks if the target OR the target's mind has the specified trait
#define HAS_MIND_TRAIT(target, trait) (HAS_TRAIT(target, trait) || (HAS_TRAIT(astype(target, /mob)?.mind, trait)))
/// Checks if the target OR the target's mind has the specified trait from the given source
#define HAS_MIND_TRAIT_FROM(target, trait, source) (HAS_TRAIT_FROM(target, trait, source) || (HAS_TRAIT_FROM(astype(target, /mob)?.mind, trait, source)))
/// Add a trait to the target, or their mind, if it exists
#define ADD_MIND_TRAIT(target, trait, source) ADD_TRAIT((astype(target, /mob)?.mind || target), trait, source)
/// Removes a trait from the target, or their mind, if it exists
#define REMOVE_MIND_TRAIT(target, trait, source) REMOVE_TRAIT((astype(target, /mob)?.mind || target), trait, source)
/// Returns a list of trait sources for the target's mind, or the target itself if no mind exists
#define GET_MIND_TRAIT_SOURCES(target, trait) (astype(target, /mob)?.mind?._status_traits?[trait] || target?._status_traits?[trait] || list())
