// component
import HomeTwoToneIcon from '@mui/icons-material/HomeTwoTone';
import LocalTaxiTwoToneIcon from '@mui/icons-material/LocalTaxiTwoTone';
import MapIcon from '@mui/icons-material/Map';
import SettingsIcon from '@mui/icons-material/Settings';
import EmojiPeopleIcon from '@mui/icons-material/EmojiPeople';
import SvgColor from '../../../components/svg-color';

// ----------------------------------------------------------------------

const icon = (name) => <SvgColor src={`/assets/icons/navbar/${name}.svg`} sx={{ width: 1, height: 1 }} />;

const navConfig = [
  {
    title: 'Overview',
    path: '/dashboard/app',
    icon: <HomeTwoToneIcon />,
  },
  {
    title: 'Drivers',
    path: '/dashboard/drivers',
    icon: icon('ic_user'),
  },

  {
    title: 'Live Dispatch',
    path: '/dashboard/taxi',
    icon: <LocalTaxiTwoToneIcon />,
  },
  {
    title: 'Reports',
    path: '/dashboard/reports',
    icon: icon('ic_analytics'),
  },
  {
    title: 'Fleet Map',
    path: '/dashboard/map',
    icon: <MapIcon />,
  },
  {
    title: 'Customers',
    path: '/dashboard/customer',
    icon: <EmojiPeopleIcon />,
  },
  {
    title: 'Settings',
    path: '/dashboard/maintenance',
    icon: <SettingsIcon />,
  },
];

export default navConfig;
